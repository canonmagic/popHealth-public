require 'rubygems'
require 'zip/zip'
require 'cql_bundle_importer.rb'
require_relative '../app/models/tracker.rb'
#require_relative '../lib/static_bundle_importer.rb'


class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  def unzip_file()
    Zip::ZipFile.open(@output_file) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(@input_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
  end

  # Zip the input directory.
  def write()
    entries = Dir.entries(@input_dir); entries.delete("."); entries.delete("..")
    io = Zip::ZipFile.open(@output_file, Zip::ZipFile::CREATE);
    write_entries(entries, "", io)
    io.close();
  end

  # A helper method to make the recursion work.
  private
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == "" ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zip_file_path)
      if File.directory?(disk_file_path)
        io.mkdir(zip_file_path)
        subdir = Dir.entries(disk_file_path)
        subdir.delete(".")
        subdir.delete("..")
        write_entries(subdir, zip_file_path, io)
      else
        io.get_output_stream(zip_file_path) do |f|
          f.print(File.open(disk_file_path, "rb").read())
        end
      end
    end
  end
end

# 12/09/16 Added last .gsub to remove ref. to defunct package Moped
def modify_bundle_dates(bundle_name)
  zf = ZipFileGenerator.new("./bundle_tmp", bundle_name)
  zf.unzip_file()
  FileUtils.rm(bundle_name)

  Dir.glob('./bundle_tmp/measures/**/*').select do |measure|
    next unless File.file? measure
    IO.write(measure, File.open(measure) do |f|
      f.read.gsub("var effective_date = <%= effective_date %>;", "var effective_date = <%= effective_date %>;\\nvar start_date = <%= start_date %>;")
          .gsub("MeasurePeriod.low.date.setFullYear(MeasurePeriod.low.date.getFullYear()-1);", "MeasurePeriod.low.date.setFullYear(MeasurePeriod.low.date.getFullYear()-1);\\nif(start_date)\\nMeasurePeriod.low.date = new Date(1000 * start_date);")
          .gsub('Moped::BSON', 'BSON')
    end
    )
  end

  zf.write()

  FileUtils.rm_rf('./bundle_tmp')
end

def import_bundle(file_path, options)
  bundle_file = File.new("bundles/#{@bundle_name}")
  importer = CqlBundle::CqlBundleImporter
  @bundle = importer.import(bundle_file, Tracker.new, false)
  if !@bundle.nil?
    #@bundle.save!
    puts "Bundle import Successful"
  end
end

def import_static_bundle(file_path)
  puts "In import_static_bundle"
  bundle_file = File.new("bundles/#{file_path}")
  importer = StaticBundle::StaticBundleImporter
  @bundle = importer.import(bundle_file)
  if !@bundle.nil?
    #@bundle.save!
    puts "Bundle import Successful"
  end
end