require_relative '../../../../lib/hds/bulk_record_importer.rb'

module Api
  module Admin
    class PatientsController < ApplicationController
      resource_description do
        resource_id 'Admin::Patients'
        short 'Patients Admin'
        formats ['json']
        description "This resource allows for the management of clinical quality measures in the popHealth application."
      end
      include ApplicationHelper
      include LogsHelper
      
      protect_from_forgery except: [:deletePatientsFromPractice, :destroy, :upload_single_patient]
      
      before_action :authenticate_user!
      before_action :validate_authorization!
      #skip_before_action :verify_authenticity_token

      api :GET, "/admin/patients/count", "Get count of patients in the database"
      formats ['json']
      example '{"patient_count":56}'
      def count
        json = {}
        json['patient_count'] = CQM::Patient.count
        render :json => json
      end

      api :POST, "/admin/patients", "Upload a zip file of patients."
      param :file, nil, :desc => 'The zip file of patients to upload.', :required => true
      param :practice_id, String, :desc => "ID for the patient's Practice", :required => false
      param :practice_name, String, :desc => "Name for the patient's Practice", :required => false

      def create
        begin
          log_call LogAction::IMPORT, "API Admin Patients Controller - Import a ZIP file with QRDA CAT I files"

          file = params[:file]
      
            practice = get_practice_parameter(params[:practice_id], params[:practice_name])
            Delayed::Worker.logger.info("What is Practice here  #{practice}")
            FileUtils.mkdir_p(File.join(Dir.pwd, "tmp/import"))
            file_location = File.join(Dir.pwd, "tmp/import")
            file_name = "patient_upload" + Time.now.to_i.to_s + rand(1000).to_s
  
            temp_file = File.new(file_location + "/" + file_name, "w")
  
            File.open(temp_file.path, "wb") { |f| f.write(file.read) }
            Delayed::Job.enqueue(ImportArchiveJob.new({'practice' => practice, 'file' => temp_file,'user' => current_user}),:queue=>:patient_import)
          render status: 200, plain: 'Patient file has been uploaded.'
        rescue Exception => e
          Delayed::Worker.logger.info(e.message)
        end
      end
      
      api :DELETE, "/admin/patients/deletePatientsFromPractice", "Delete all the patients from a practice (practice_id)"
      param :practice_id, String, :desc => "Practice ID", :required => true
      def deletePatientsFromPractice
        log_call LogAction::DELETE, "API Admin Patients Controller - Remove all patients from a practice"

        Delayed::Worker.logger.info("********** Im in deletePatientsFromPractice *************")
         #log_admin_api_call LogAction::DELETE, "Removed patients from practice" + params[:practice_id], true
         remove_patients_from_practice(params[:practice_id]) #see ApplicationHelper module

         render status: 200, plain: "Patients removed from practice: " + params[:practice_id]
      end
      

      api :DELETE, "/admin/patients", "Delete all patients in the database."
      def destroy
        log_call LogAction::DELETE, "API Admin Patients Controller - Remove all patients"

        CQM::Patient.delete_all

        render status: 200, plain: 'Patient records successfully removed from database.'
      end

      api :PUT, "/patient", "Load a single patient XML file into popHealth"
      formats ['xml']
      param :file, nil, :desc => "The XML patient file", :required => true
      param :practice_id, String, :desc => "ID for the patient's Practice", :required => false
      param :practice_name, String, :desc => "Name for the patient's Practice", :required => false
      description "Upload a single XML file for a patient into popHealth."
      def upload_single_patient

        log_call LogAction::IMPORT, "API Admin Patients Controller - Import a QRDA CAT I file"

        begin
         filedata = request.body.read
        xml_filedata_index = filedata.index('<?xml version="1.0" encoding="utf-8"?>')
        len = filedata.length - xml_filedata_index
        filedata = filedata[xml_filedata_index, len]
       
        file = StringIO.new(filedata.to_s)
        practice = get_practice_parameter(params[:practice_id], params[:practice_name])

        FileUtils.mkdir_p(File.join(Dir.pwd, "tmp/import"))
        file_location = File.join(Dir.pwd, "tmp/import")
        file_name = "patient_upload" + Time.now.to_i.to_s + rand(1000).to_s

        temp_file = File.new(file_location + "/" + file_name, "w")

        File.open(temp_file.path, "wb") { |f| f.write(file.read) }
        
        rescue Exception => e
          Delayed::Worker.logger.info(e.message)
          Delayed::Worker.logger.info(e.backtrace.inspect)
        end

        begin
          response_hash = BulkRecordImporter.import_file(temp_file,File.new(temp_file).read,'tmp/error',{},practice)
          status_code = 200
        rescue Exception => e
          status_code = 500
          Delayed::Worker.logger.info(e.backtrace.inspect)
          Delayed::Worker.logger.info(e.message)
        end

        if response_hash == nil
          status_text = 'File not uploaded'
          status_code = 400
        elsif response_hash == false
          status_text = 'Patient could not be saved'
          status_code = 400
        elsif response_hash == true
          status_text = "Patient upload successful"
          status_code = 200
        else
          status_text = response_hash[:message]
          status_code = response_hash[:status_code]
        end

        FileUtils.rm_rf Dir.glob("tmp/import/*")
        render plain: status_text, status: status_code
      end

      private

      def validate_authorization!
        authorize! :admin, :users
      end
    end
  end
end
