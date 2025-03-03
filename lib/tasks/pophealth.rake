require_relative '../measure_dates.rb'

=begin
require 'open-uri'
require 'highline/import'
#require 'rake/testtask'

=end
namespace :pophealth do
  task :setup => :environment
=begin
  desc "Removes properties from the measures document that are not needed by popHealth"
  task :prune_measures => :environment do
    HealthDataStandards::CQM::Measure.each do |measure|
      measure.remove_attribute(:hqmf_document)
      measure.remove_attribute(:data_criteria)
      measure.save!
    end
  end

  desc "Remove a bundle from the db"
  task :drop_bundle, [:version] => :environment do |t,args|
    if args.version
      Bundle.where({version: args.version}).each{|b| b.delete}
    end

  end
=end
  task :download_value_sets, [:username, :password] => :environment do |t, args|
    valuesets = Measure.all.collect {|m| m['oids']}
    errors = {}
    valuesets.flatten!
    valuesets.compact!
    valuesets.uniq!
    config = APP_CONFIG['value_sets']
    api = HealthDataStandards::Util::VSApi.new(config["ticket_url"],config["api_url"],args.username,args.password)
    RestClient.proxy = ENV["http_proxy"]
    valuesets.each_with_index do |oid,index| 
      begin
        vs_data = api.get_valueset(oid) 
        vs_data.force_encoding("utf-8") # there are some funky unicodes coming out of the vs response that are not in ASCII as the string reports to be
        doc = Nokogiri::XML(vs_data)

        doc.root.add_namespace_definition("vs","urn:ihe:iti:svs:2008")
        vs_element = doc.at_xpath("/vs:RetrieveValueSetResponse/vs:ValueSet")
        
        if vs_element && vs_element["ID"] == oid
        vs_element["id"] = oid
          vs = HealthDataStandards::SVS::ValueSet.load_from_xml(doc)
          # look to see if there is a valueset with the given oid and version already in the db
          old = HealthDataStandards::SVS::ValueSet.where({:oid=>vs.oid, :version=>vs.version}).first
          if old.nil?
           vs.save!
          end
        else
          errors[oid] = "Not Found"
        end
      rescue 
        errors[oid] = $!.message
      end
      print "\r"
      print "#{index+1} of #{valuesets.length} processed : error downloading #{errors.keys.length} valuesets"
      STDOUT.flush
    end

    if !errors.empty?
      File.open("oid_errors.txt", "w") do |f|
      f.puts errors.to_yaml
    end
      puts ""
      puts "There were errors retreiveing #{errors.keys.length} valuesets. Cypress May not work correctly without thses valusets installed."
      puts "A list of the valueset OIDs that were unable to be retrieved have been written to the file oid_errors.txt"
   end
  end

  desc %{ Download measure/test deck bundle.
    options
    nlm_user    - the nlm username to authenticate to the server - will prompt is not supplied
    nlm_passwd  - the nlm password for authenticating to the server - will prompt if not supplied
    version     - the version of the bundle to download. This will default to the version
                  declared in the config/cypress.yml file or to the latest version if one does not exist there"

   example usage:
    rake cypress:bundle_download nlm_name=username nlm_passwd=password version=2.1.0-latest
  }

  task :download_bundle => :setup do
    nlm_user = ENV["nlm_user"]
    nlm_passwd = ENV["nlm_pass"]
    measures_dir = File.join(Rails.root, "bundles")
    while nlm_user.nil? || nlm_user == ""
      STDOUT.puts "NLM Username?: "
      nlm_user = STDIN.gets.strip
    end

    while nlm_passwd.nil? || nlm_passwd == ""
      STDOUT.puts "NLM API Key?: "
      nlm_passwd = STDIN.gets.strip
    end

    bundle_version = ENV["version"] || APP_CONFIG["default_bundle"] || "latest"
    @bundle_name = "bundle-#{bundle_version}.zip"

    puts "Downloading and saving #{@bundle_name} to #{measures_dir}"
    # Pull down the list of bundles and download the version we're looking for
    bundle_uri = "https://cypressdemo.healthit.gov/measure_bundles/#{@bundle_name}"
    bundle = nil

    tries = 0
    max_tries = 10
    last_error = nil
    while bundle.nil? && tries < max_tries do
      tries = tries + 1
      begin
        bundle = OpenURI.open_uri(bundle_uri, :proxy => ENV["http_proxy"], :http_basic_authentication=>[nlm_user, nlm_passwd])
      rescue OpenURI::HTTPError => oe
        last_error = oe
        if oe.message == "401 Unauthorized"
          puts "Please check your credentials and try again"
          break
        end
      rescue => e
        last_error = e
        sleep 0.5
      end
    end

    if bundle.nil?
       puts "An error occured while downloading the bundle"
      raise last_error if last_error
    end
    
    # Save the bundle to the measures directory
    FileUtils.mkdir_p measures_dir
    FileUtils.mv(bundle.path, File.join(measures_dir, @bundle_name))
  end

  desc %{ Download and install the measure/test deck bundle.  This is essientally delegating to the bundle_download and bundle:import tasks
    options
    nlm_user    - the nlm username to authenticate to the server - will prompt is not supplied
    nlm_passwd  - the nlm password for authenticating to the server - will prompt if not supplied
    version     - the version of the bundle to download. This will default to the version
                  declared in the config/cypress.yml file or to the latest version if one does not exist there"
    delete_existing - delete any existing bundles with the same version and reinstall - default is false - will cause error if same version already exists
    update_measures - update any existing measures with the same hqmf_id to those contained in this bundle.
                      Will only work for bundle versions greater than that of the installed version - default is false
    type -  type of measures to be installed from bundle. A bundle may have measures of different types such as ep or eh.  This will constrain the types installed, defautl is all types
   example usage:
    rake cypress:bundle_download_and_install nlm_name=username nlm_passwd=password version=2.1.0-latest  type=ep
  }
  task :bundle_download_and_install => [:download_bundle] do
    de = ENV['delete_existing'] || false
    um = ENV['update_measures'] || false
    puts "Importing bundle #{@bundle_name} delete_existing: #{de}  update_measures: #{um} type: #{ENV['type'] || 'ALL'}"
    task("bundle:import").invoke("bundles/#{@bundle_name}",de, um , ENV['type'])
  end

  desc 'Modify an existing bundle to support variable dates and then import it'
  task :update_import, [:bundle_path,  :delete_existing,  :update_measures, :type, :create_indexes, :exclude_results] => :environment do |task, args|
    puts "Modifying bundle #{args.bundle_path} to support variable date ranges"
    modify_bundle_dates(args.bundle_path)
    task("bundle:import").invoke(args.bundle_path, args.delete_existing, args.update_measures, args.type, args.create_indexes, args.exclude_results)
  end

  desc 'Automatically downloads bundle and modifies for variable dates. See download_bundle for params'
  task :download_update_install => [:download_bundle] do
    options ={:delete_existing => false,
      :update_measures => false}
    puts "Modifying bundle #{@bundle_name} to support variable date ranges"
    modify_bundle_dates("bundles/#{@bundle_name}")
    import_bundle(@bundle_name,options)
    task("pophealth:remove_artifacts").invoke
  end

  desc 'Adds date modification to import of bundle on disk'
  task :import , [:bundle_path] do |task, args|
    de = ENV['delete_existing'] || false
    um = ENV['update_measures'] || false

    @bundle_name=args.bundle_path
    puts "Modifying bundle #{@bundle_name} to support variable date ranges"
    modify_bundle_dates(@bundle_name)
    task("bundle:import").invoke(@bundle_name,de, um , ENV['type'])
    #task("pophealth:remove_artifacts").invoke
  end

  desc 'Removes Cypress artifacts of patient_cache, query_cache, and records'
  task :remove_artifacts => :environment do 
    puts "Cleaning out records and caches"
    #CQM::Patient.delete_all
    #HealthDataStandards::CQM::QueryCache.delete_all
    #QDM::IndividualResult.delete_all
  end

  desc 'Renews the logs file automatically'
  task :actions_log_renew => :environment do

    file_contents = File.read("./log/popHealth.log")
    File.write("./log_history/#{DateTime.now}_popHealth.log", file_contents)
    File.delete("./log/popHealth.log")
    File.open("./log/popHealth.log", "w")

    log_version = LogVersion.create()
  end

  desc 'Creates a copy of logs and verifies for any possible alteration'
  task :actions_log_verify => :environment do

    file_contents = File.read("./log/popHealth.log")

    # First check for current version hashes
    log_version = LogVersion.last
    hashes = []
    LogHash.where(log_version_id: log_version.id).each { |lh| hashes << lh }

    # If there is not hashes and file is not empty, this is a new log, so let's create the first hash
    if( hashes.count < 1 && file_contents.length > 0 )

      hash = Digest::MD5.hexdigest(file_contents)
      LogHash.create( :hash => hash, :log_version_id => log_version.id, :starting_character => 0, :ending_character => ( file_contents.length - 1 ), :created_at => DateTime.now() )

    elsif( hashes.count > 0 )
      
      hashes.each { |h| 
        hash = h[:hash]
        file_portion = file_contents[h.starting_character..h.ending_character]
        file_hash = Digest::MD5.hexdigest(file_portion)

        unless( hash == file_hash )
          PopHealth::Application.config.actions_logger.info "-->> Log alteration detected <<--"
          next
        else
        end
      }      

      last_h = hashes.last
      file_portion = file_contents[last_h.ending_character+1..-1]

      if( file_portion.length > 0 )
        file_hash = Digest::MD5.hexdigest(file_portion)
        LogHash.create( :hash => file_hash, :log_version_id => log_version.id, :starting_character => last_h.ending_character+1, :ending_character => ( last_h.ending_character + file_portion.length ), :created_at => DateTime.now() )
      end
    end

    # This is unnecesary, just for debugging purposes
    #PopHealth::Application.config.actions_logger.info "-->> Log verified sucessfully <<--"
  end
end
