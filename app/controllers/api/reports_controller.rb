require 'c4_helper'
require 'cypress/expected_results_calculator'
require 'cypress/scoop_and_filter'
require 'spreadsheet' #ADD BY JOSE MELENDEZ. REQUIRE TO GENERATE EXCEL

module Api
  class ReportsController < ApplicationController
    resource_description do
      short 'Reports'
      formats ['xml']
      description <<-RCDESC
        This resource is responsible for the generation of QRDA Category III reports from clincial
        quality measure calculations.
      RCDESC
    end
    include LogsHelper
    before_action :authenticate_user!
    skip_authorization_check

    api :GET, '/reports/*qrda_cat3.xml', "Retrieve a QRDA Category III document"
    param :measure_ids, Array, :desc => 'The HQMF ID of the measures to include in the document', :required => false
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period',
          :required => false
    param :effective_start_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period',
          :required => false
    param :provider_id, String, :desc => 'The Provider ID for CATIII generation'
    param :cms_program, String, :desc => 'CMS Program Name NONE/MIPS',
          :required => false
    #Add Jose Melendez (falta este argumento para que se pueda generar el reporte)
    param :filter_preferences, Array, :desc => '', :required => false
    #
    description <<-CDESC
      This action will generate a QRDA Category III document. If measure_ids and effective_date are not provided,
      the values from the user's dashboard will be used.
    CDESC

    def cat3
      @patients=[]
      @msrs = []
      begin
        log_api_call LogAction::EXPORT, "QRDA Category 3 report"

        measure_ids = params[:measure_ids] ||current_user.preferences["selected_measure_ids"]
        program = !(params[:cms_program] == nil) ? params[:cms_program].upcase : APP_CONFIG['qrda_cms_program'].upcase

        provider_id = params[:provider_id]
          CQM::Patient.all.each do |p|
            p.qdmPatient.extendedData["provider_performances"].each do |pp|
              pdata = JSON.parse(pp).select{|pid| pid["provider_id"] == provider_id}
              if pdata.present?
                  @patients << p
              end
            end
          end

        measure_ids.each do |measure|
          @msr = Measure.where(_id: measure).first
          if @msr.present?
          @msrs << @msr
          else
          @msr = Measure.where(hqmf_id: measure).first
            if @msr.present?
              @msrs << @msr
            end
          end
        end

        # C4-mods : should we flag them so they can be conditional?
        fname=''
        cms_measures=nil

        if !measure_ids.nil?
          cms_measures= Measure.in(:hqmf_id => measure_ids).collect { |m| m.cms_id }.uniq
          fname=cms_measures.join('_')+'_'
        end
        
        c4_filters=current_user.preferences['c4filters']
        fname = fname+c4_filters.join('_')+'_' if !c4_filters.nil?
        # end C4-mods

        fname=fname+'qrda_cat3.xml'
        filter = measure_ids=="all" ? {} : {:hqmf_id.in => measure_ids}
        effective_date = params["effective_date"] || current_user.effective_date || Time.gm(2020, 12, 31)
        start_time = params["effective_start_date"] || current_user.effective_start_date || Time.gm(2019, 12, 31)
        filter_preferences = params["filter_preferences"] || c4_filters
        correlation_id = IndividualResult.where('measure_id' => @msrs.first.id).first.correlation_id
        erc = Cypress::ExpectedResultsCalculator.new(@patients,correlation_id,effective_date,start_time, filter_preferences)
        @results = erc.aggregate_results_for_measures(@msrs)
        prov = Provider.where(id: provider_id).first

        
        prov['ids'] = []
        if prov.npi != nil
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.6", "value" => "#{prov.npi}"})  
        else
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.6", "value" => "#{APP_CONFIG['default_practice_npi']}"}) if APP_CONFIG['default_practice_npi']
        end
        if prov.tin != nil
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.2", "value" => "#{prov.tin}"})  
        else
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.2", "value" => "#{APP_CONFIG['default_practice_tin']}"}) if APP_CONFIG['default_practice_tin']
        end
        if prov.ccn != nil
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.336", "value" => "#{prov.ccn}"})
        else
          prov['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.336", "value" => "#{APP_CONFIG['default_practice_ccn']}"}) if APP_CONFIG['default_practice_ccn']
        end
        options = {provider: prov, submission_program: program, start_time: Time.at(start_time.to_i).utc.to_datetime, end_time: Time.at(effective_date.to_i).utc.to_datetime, ry2022_submission: true}
        # QRDA3R21 IS OUTDATED, CHANGED IT FOR QRDA3
        cat_3_xml = Qrda3.new(@results, @msrs, options).render
        render xml: cat_3_xml, content_type: "attachment/xml"
=begin
        bndl = (b = Bundle.all.sort(:version => :desc).first) ? b.version : 'n/a'
        cat3ver = nil
        case program
        when 'MIPS'
            cat3ver='r2_1/ep'
            @cms_program = practice ? 'MIPS_GROUP': 'MIPS_INDIV'
        when 'NONE'
            cat3ver='r2_1'
        end
        exporter = HealthDataStandards::Export::Cat3.new(cat3ver)
=end
        
=begin
        providers = []
        provider_filter = nil
        provider_filter = {}
        if params[:provider_id].present?
          if practice
            providers = Provider.where(parent_id: params[:provider_id]).to_a
          else
            providers = Provider.find(params[:provider_id]).to_a
          end
          provider_filter['filters.providers'] = params[:provider_id] if params[:provider_id].present?
        end
        xml = exporter.export(HealthDataStandards::CQM::Measure.top_level.where(filter),
                              generate_header(providers),
                              effective_date.to_i,
                              Time.at(effective_start_date.to_i),
                              end_date,
                              cat3ver)
        # FileUtils.mkdir('results') if !File.exist?('results')
        # File.open('results/'+fname, 'w') { |f| f.write(xml) }
        render xml: xml, content_type: "attachment/xml"
=end
      rescue Errno::ENOENT => e
        Delayed::Worker.logger.info(e.message)
        Delayed::Worker.logger.info(e.backtrace)

        render :status => :not_implemented, text: "No such the templates for the cat3"
      end
    end

    api :GET, '/reports/*cat1.zip', "Retrieve a QRDA Category I document"
    param :provider_id, String, :desc => 'The Provider ID for CATIII generation', :required => false
    param :cmsid, String, :desc => "CMSnnvn used for file name and for measure retrieval", :required => true
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period',
          :required => false
    param :effective_start_date, String, :desc => 'Time in seconds since the epoch for the start date of the reporting period',
          :required => false
    description <<-CDESC
      This action will generate a QRDA Category I Zip file with dupes removed and honoring any filters.
    CDESC

    def cat1_zip
      log_api_call LogAction::EXPORT, "QRDA Category 1 report", true
      begin
      #qdm_patient_converter = CQM::Converter::QDMPatient.new
      FileUtils.mkdir('results') if !File.exist?('results')
      filepath='results/' + params[:cmsid] +'_'
      filepath += (current_user.preferences['c4filters'] or []).join('_')
      filepath += (filepath.end_with?('_') ? '' : '_') + 'cat1.zip'
      file = File.new(filepath, 'w')
      measures= Measure.where(:cms_id => params[:cmsid])
      #measures=HealthDataStandards::CQM::Measure.where(:cms_id => params[:cmsid]).to_a
      patients=[]
      IndividualResult.where('extendedData.hqmf_id' => measures.first.hqmf_id).each do |pc|
        if !pc['extendedData.manual_exclusion'] && pc['IPP'] > 0
          p = Patient.find(pc['patient_id'])
          authorize! :read, p
          patients.push({:record => p}) if p.present?
        end
      end
      end_date = params["effective_date"] || current_user.effective_date || Time.gm(2020, 12, 31)
      start_date = params["effective_start_date"] || current_user.effective_start_date || end_date.years_ago(1)
      c4h = C4Helper::Cat1ZipFilter.new(measures, start_date, end_date)
      c4h.pluck(filepath, patients)
      File.open(filepath, 'r') do |f|
        send_data(f.read, type: 'application/zip', disposition: 'attachment')
      end
      File.delete(filepath);
      #send_file(filepath, type: "application/zip", disposition: 'attachment')
      nil
      rescue Exception => e
        puts "Error in exporting CAT 1 file "
        puts e.message
        puts e.backtrace.inspect
      end 
    end

    api :GET, "/reports/patients" #/:id/:sub_id/:effective_date/:provider_id/:patient_type"
    param :id, String, :desc => "Measure ID", :required => true
    param :sub_id, String, :desc => "Measure sub ID", :required => false
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period'
    param :effective_start_date, String, :desc => 'Time in seconds since the epoch for the start date of the reporting period'
    param :provider_id, String, :desc => 'Provider ID for filtering quality report', :required => true
    param :patient_type, String, :desc => 'Outlier, Numerator, Denominator', :required => true
    description <<-CDESC
      This action will generate an Excel spreadsheet of relevant QRDA Category I Document based on the category of patients selected. 
    CDESC

    def patients
      log_api_call LogAction::EXPORT, "Patients report", true
      type = params[:patient_type]
      qr = QME::QualityReport.where(:effective_date => params[:effective_date].to_i, :measure_id => params[:id], :sub_id => params[:sub_id], "filters.providers" => params[:provider_id])

      authorize! :read, Provider.find(params[:provider_id])
      records = (qr.count > 0) ? qr.first.patient_results : []

      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      format = Spreadsheet::Format.new :weight => :bold

      measure = HealthDataStandards::CQM::Measure.where(id: params[:id]).first

      end_date = params[:effective_date] || current_user.effective_date || Time.gm(2015, 12, 31)
      start_date = params[:effective_start_date] || current_user.effective_start_date || Time.gm(2014, 12, 31)

      end_date = Time.at(end_date.to_i).strftime("%D")
      start_date = Time.at(start_date.to_i).strftime("%D")

      # report header
      r=0
      sheet.row(r).push("Measure ID: ", '', measure.cms_id + ", " + "NQF" + measure.nqf_id)
      sheet.row(r+=1).push("Name: ", '', measure.name)
      sheet.row(r+=1).push("Description: ", '', measure.description)
      sheet.row(r+=1).push("Reporting Period: ", '', start_date + " - " + end_date)
      sheet.row(r+=1).push("Group: ", '', patient_type(type))
      (0..r).each do |i|
        sheet.row(i).set_format(0, format)
      end
      # table headers
      sheet.row(r+=2).push('MRN', 'First Name', 'Last Name', 'Gender', 'Birthdate')
      sheet.row(r).default_format = format
      # populate rows
      r+=1

      records.each do |record|
        value = record.extendedData
        authorize! :read, CQM::Patient.find_by('extendedData.medical_record_number': value[:medical_record_number])
        #Todo makesure IPP =1 in js ecqm engine
        if record["#{type}"]
          if record["#{type}"] >= 1
            sheet.row(r).push(value[:medical_record_number], value[:first][0], value[:last], value[:gender], Time.new(value[:DOB][:year],value[:DOB][:month],value[:DOB][:day]).strftime("%D"))
            r +=1
          end
        end
      end

      today = Time.now.strftime("%D")
      filename = "patients_" + measure.cms_id + "_" + patient_type(type) + "_" + "#{today}" + ".xls"
      data = StringIO.new '';
      book.write data;
      send_data(data.string, {
          :disposition => 'attachment',
          :encoding => 'utf8',
          :stream => false,
          :type => 'application/vnd.ms-excel',
          :filename => filename
      })
    end

    api :GET, '/reports/team_report', "Retrieve a QRDA Category III document"
    param :measure_id, String, :desc => 'The HQMF ID of the measure to include in the document', :required => true
    param :sub_id, String, :desc => 'The sub ID of the measure to include in the document', :required => false
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period', :required => true
    param :team_id, String, :desc => 'The ID of the team for the measure report'
    description <<-CDESC
      This action will generate a Excel spreadsheet report for a team of providers for a given measure.
    CDESC

    def team_report
      log_api_call LogAction::EXPORT, "Team report"
      measure_id = params[:measure_id]
      sub_id = params[:sub_id]
      team = Team.find(params[:team_id])

      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      format = Spreadsheet::Format.new :weight => :bold

      if sub_id
        measure = HealthDataStandards::CQM::Measure.where(:id => measure_id, :sub_id => sub_id).first
      else
        measure = HealthDataStandards::CQM::Measure.where(:id => measure_id).first
      end

      eff = Time.at(params[:effective_date].to_i)
      end_date = eff.strftime("%D")
      start_date = eff.month.to_s + "/" + eff.day.to_s + "/" + (eff.year-1).to_s
      # report header
      r=0
      sheet.row(r).push("Measure ID: ", measure.cms_id + ", " + "NQF" + measure.nqf_id)
      sheet.row(r+=1).push("Name: ", measure.name)
      sheet.row(r+=1).push("Reporting Period: ", start_date + " - " + end_date)
      sheet.row(r+=1).push("Team: ", team.name)
      (0..r).each do |i|
        sheet.row(i).set_format(0, format)
      end
      # table headers
      sheet.row(r+=2).push('Provider Name', 'NPI', 'Numerator', 'Denominator', 'Exclusions', 'Percentage')
      sheet.row(r).default_format = format
      # populate rows
      r+=1
      providers = team.providers.map { |id| Provider.find(id) }
      providers.each do |provider|
        authorize! :read, provider
        query = {:measure_id => measure_id, :sub_id => sub_id, :effective_date => params[:effective_date].to_i, 'filters.providers' => [provider.id.to_s]}
        cache = QME::QualityReport.where(query).first
        if cache && cache.result
          performance_denominator = cache.result['DENOM'] - cache.result['DENEX']
          percent = percentage(cache.result['NUMER'].to_f, performance_denominator.to_f)
          sheet.row(r).push(provider.full_name, provider.npi, cache.result['NUMER'], performance_denominator, cache.result['DENEX'], percent)
          r+=1
        end
      end

      today = Time.now.strftime("%D")
      filename = team.name + "_report_" + measure.cms_id + "_" + "#{today}" + ".xls"
      data = StringIO.new '';
      book.write data;
      send_data(data.string, {
          :disposition => 'attachment',
          :encoding => 'utf8',
          :stream => false,
          :type => 'application/vnd.ms-excel',
          :filename => filename
      })
    end

    api :GET, '/reports/measures_spreadsheet', "Retrieve a spreadsheet of measure calculations"
    param :username, String, :desc => 'Username of user to generate reports for'
    param :measure_ids, Array, :desc => 'The HQMF ID of the measures to include in the document', :required => false
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period'
    param :effective_start_date, String, :desc => 'Time in seconds since the epoch for the start date of the reporting period'
    param :provider_id, String, :desc => 'The Provider ID for spreadsheet generation', :required => true
    description <<-CDESC
      This action will generate an Excel spreadsheet document containing a list of measure calculations for the current user's selected measures.
    CDESC

    def measures_spreadsheet
      log_api_call LogAction::EXPORT, "Measure spreadsheet report"
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      format = Spreadsheet::Format.new :weight => :bold

      user = User.where(:username => params[:username]).first || current_user
      effective_date = params[:effective_date] || current_user.effective_date
      effective_start_date = params[:effective_start_date] || current_user.effective_start_date
      measure_ids = params[:measure_ids] ||user.preferences["selected_measure_ids"]

      unless measure_ids.empty?
        selected_measures = measure_ids.map { |id| HealthDataStandards::CQM::Measure.where(:id => id) }
        # report header
        provider = Provider.find(params[:provider_id])
        authorize! :read, provider

        end_date = params[:effective_date] || current_user.effective_date || Time.gm(2015, 12, 31)
        start_date = params[:effective_start_date] || current_user.effective_start_date || Time.gm(2014, 12, 31)

        end_date = Time.at(end_date.to_i).strftime("%D")
        start_date = Time.at(start_date.to_i).strftime("%D")

        r=0
        sheet.row(r).push("Reporting Period: ", '', start_date + " - " + end_date)
        sheet.row(r+=1).push("Provider: ", '', provider.full_name)
        sheet.row(r+=1).push("NPI: ", '', provider.npi)
        (0..r).each do |i|
          sheet.row(i).set_format(0, format)
        end
        # table headers
        sheet.row(r+=2).push('NQF ID', 'CMS ID', 'Sub ID', 'Title', 'Subtitle', 'Numerator', 'Denominator', 'Exclusions', 'Percentage')
        sheet.row(r).default_format = format

        # populate rows
        r+=1
        selected_measures.each do |measure|
          measure.sort_by! { |s| s.sub_id }.each do |sub|
            query = {:measure_id => sub.measure_id, :sub_id => sub.sub_id, :effective_date => effective_date, 'filters.providers' => [provider.id.to_s]}
            cache = QME::QualityReport.where(query).first
            performance_denominator = cache.result['DENOM'] - cache.result['DENEX']
            percent = percentage(cache.result['NUMER'].to_f, performance_denominator.to_f)
            sheet.row(r).push(sub.nqf_id, sub.cms_id, sub.sub_id, sub.name, sub.subtitle, cache.result['NUMER'], performance_denominator, cache.result['DENEX'], percent)
            r+=1
          end
        end
      end
      today = Time.now.strftime("%D")
      filename = "measure-report_" + "#{today}" + ".xls"

      data = StringIO.new '';
      book.write data;
      send_data(data.string, {
          :disposition => 'attachment',
          :encoding => 'utf8',
          :stream => false,
          :type => 'application/vnd.ms-excel',
          :filename => filename
      })
    end


    api :GET, "/reports/cat1/:id/:measure_ids"
    formats ['xml']
    param :id, String, :desc => "Patient ID", :required => true
    param :measure_ids, String, :desc => "Measure IDs", :required => true
    param :effective_date, String, :desc => 'Time in seconds since the epoch for the end date of the reporting period',
          :required => false
    param :effective_start_date, String, :desc => 'Time in seconds since the epoch for the start date of the reporting period',
          :required => false
    description <<-CDESC
      This action will generate a QRDA Category I Document. Patient ID and measure IDs (comma separated) must be provided. If effective_date is not provided,
      the value from the user's dashboard will be used.
    CDESC

    def cat1
      log_api_call LogAction::EXPORT, "QRDA Category 1 report", true
      p = CQM::Patient.find(params[:id])
      authorize! :read, p
      measure_ids = params["measure_ids"].split(',')
      end_date = params["effective_date"] || current_user.effective_date || Time.gm(2020, 12, 31)
      start_date = params["effective_start_date"] || current_user.effective_start_date || end_date.years_ago(1)
      end_date = end_date.to_i
      start_date = start_date.to_i
      measures = Measure.where(:hqmf_id.in => measure_ids)
      patient_scoop_and_filter = Cypress::ScoopAndFilter.new(measures)

      #the below statments are adapted from lib/c4_helper.rb
      options = { start_time: Time.at(start_date).to_datetime, end_time: Time.at(end_date).to_datetime}
      sf_patient = p.clone
      sf_patient.id = p.id
      # CMS529 requires that entries point to the ecounters that they are related to
      sf_patient.add_encounter_ids_to_events unless (measures.map(&:hqmf_set_id) & APP_CONFIG['result_measures'].map(&:hqmf_set_id)).empty?
      patient_scoop_and_filter.scoop_and_filter(sf_patient)
      #Including Provider Details In a way CQM-Report wants it
      provider = Provider.where('_id' => p.provider_ids[0]).first
      options[:provider] = provider
      options[:provider]['ids'] = []
      options[:provider]['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.6", "value" => "#{provider.npi}"})  if provider.npi
      options[:provider]['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.2", "value" => "#{provider.tin}"})  if provider.tin
      options[:provider]['ids'].push( {"namingSystem" => "2.16.840.1.113883.4.336", "value" => "#{provider.ccn}"})  if provider.ccn
      options[:submission_program] = APP_CONFIG['cda_header'].information_recipient.identifier.extension if APP_CONFIG['cda_header'].information_recipient      

      render xml: Qrda1R5.new(sf_patient, measures, options).render
    end


    private

    def patient_type(type)
      # IPP, NUMER, DENOM, antinumerator, DENEX
      case type
        when "IPP"
          "Initial Patient Population"
        when "NUMER"
          "Numerator"
        when "DENOM"
          "Denominator"
        when "antinumerator"
          "Outlier"
        when "DENEX"
          "Exclusion"
        else
          "N/A"
      end
    end

    def percentage(numer, denom)
      if denom == 0
        0
      else
        (numer/denom * 100).round(1)
      end
    end

    def generate_header(providers)
      header = Qrda::Header.new(APP_CONFIG["cda_header"])

      header.identifier.root = UUID.generate
      header.authors.each { |a| a.time = Time.now }
      header.legal_authenticator.time = Time.now
      header.performers = providers
      header.information_recipient.identifier.extension = @cms_program
      header
    end
  end
end
