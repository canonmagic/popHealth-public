#require 'cqm/converter'
module Api
  class PatientsController < ApplicationController
    resource_description do
      short 'Patients'
      description <<-PCDESC
        This resource allows for the management of patient records in the popHealth application.
        Patient records can be inserted into popHealth in QRDA Category I format through this resource.
        Additionally, patient information may be retrieved from popHealth. This includes popHealth's
        internal representation of a patient as well as results for clinical quality measure calculations
        for a particular patient.

        Ids used for patients by this resource are the MongoDB identifier for the patient, not the
        patient's medical record number.
      PCDESC
    end
    include PaginationHelper
    include ApplicationHelper
    include PatientsHelper
    include LogsHelper
    
    respond_to :json
    before_action :authenticate_user!
    before_action :validate_authorization!
    before_action :load_patient, :only => [:show, :delete, :toggle_excluded, :results]
    before_action :set_pagination_params, :only => :index
    before_action :set_filter_params, :only => :index
    skip_before_action :verify_authenticity_token # API doesn't need CSRF

    def_param_group :pagination do
      param :page, /\d+/
      param :per_page, /\d+/
    end

    api :GET, "/patients", "Get a list of patients"
    param_group :pagination
    formats ['json']
    def index
      records = Patient.where(@query)
      validate_record_authorizations(records)
      
      log_call LogAction::SEARCH, "API Patients Controller - List Patients"

      render json: paginate(api_patients_url,records)
    end

    api :GET, "/patients/:id[?include_results=:include_results]", "Retrieve an individual patient"
    formats ['json']
    param :id, String, :desc => "Patient ID", :required => true
    param :include_results, String, :desc => "Include measure calculation results", :required => false
    example '{"_id":"52fbbf34b99cc8a728000068","birthdate":1276869600,"first":"John","gender":"M","last":"Peters","encounters":[{...}], ...}'
    def show
      Delayed::Worker.logger.info("**************Patient Show************")
      json_methods = [:language_names]
      Delayed::Worker.logger.info(json_methods)
      json_methods << :cache_results if params[:include_results]
      Delayed::Worker.logger.info(json_methods)
      json = @patient.as_json({methods: json_methods})
      Delayed::Worker.logger.info("************** JSON obj 1 ************")
      Delayed::Worker.logger.info(json)
      json["race"]["name"] = race(@patient) if json["race"]
      Delayed::Worker.logger.info("************** JSON obj 2 ************")
      Delayed::Worker.logger.info(json)
      json["ethnicity"]["name"] = ethnicity(@patient) if json["ethnicity"]
      Delayed::Worker.logger.info("************** JSON obj 3 ************")
      Delayed::Worker.logger.info(json)
      #provider_list = []
      #@patient.qdmPatient.extendedData.provider_performances.each do |prov|
        #provider_id = JSON.parse(prov).select{|pid| pid["provider_id"]}
        #Delayed::Worker.logger.info(provider_id)
        #provider_list << provider_id
      #end

      #provider_list.each do |prov|
        #if prov
          
          #Delayed::Worker.logger.info(prov)
            #provider = CQM::Provider.find(prov)
            provider_id = @patient.provider_ids.first
            provider = Provider.find(provider_id)
            Delayed::Worker.logger.info("*************** provider ")
            Delayed::Worker.logger.info(provider)
            if provider
            json['provider_name'] = provider.givenNames
            end
        #end
      #end
      #if results = json.delete('cache_results')
        #json['measure_results'] = results_with_measure_metadata(results)
      #end

      log_call LogAction::READ, "API Patients Controller - View individual patient", params[:id]
      #log_api_call LogAction::READ, 'Patient record viewed', true
      render :json => json
    end

    api :POST, "/patients", "Load a patient into popHealth"
    formats ['xml']
    param :file, nil, :desc => "The QRDA Cat I file", :required => true
    param :practice_id, String, :desc => "ID for the patient's Practice", :required => false
    param :practice_name, String, :desc => "Name for the patient's Practice", :required => false
    description "Upload a QRDA Category I document for a patient into popHealth."
    def create
      authorize! :create, Patient

      if params[:practice_id]
        ext = Practice.where(id: params[:practice_id]).first

        if ext
          practice =  ext.try(:_id).to_s
          success = BulkRecordImporter.import(params[:file], {}, practice)
          
          if success
            log_call LogAction::CREATE, "API Patients Controller - Upload QRDA CAT I with patient information"
            render status: 201, json: 'Patient Imported'
          else
            render status: 500, json: 'Patient record did not save properly'
          end
        else
          render status: 500, json: 'Practice not found'
        end
      else
        render status: 500, json: 'Practice not found'
      end
      
    end

    def toggle_excluded
      # TODO - figure out security constraints around manual exclusions -- this should probably be built around
      # the security constraints for queries

      ManualExclusion.toggle!(@patient, params[:measure_id], params[:sub_id], params[:rationale], current_user)
      log_call LogAction::UPDATE, "API Patients Controller - Toggle patient exclusions"

      redirect_to :controller => :measures, :action => :patients, :id => params[:measure_id], :sub_id => params[:sub_id]
    end

    #Add Jose Melendez, 10/17/2023

    def patient_count

      patient_count = Patient.count
      respond_to do |format|
        format.json { render json: { patient_count: patient_count } }
      end

    end

    #

    api :DELETE, '/records/:id', "Remove a patient from popHealth"
    param :id, String, :desc => 'The id of the patient', :required => true
    def destroy
      authorize! :delete, @patient
      log_call LogAction::DELETE, "API Patients Controller - Delete a patient"

      @patient.destroy

      render :status=> 204, text=> ""
    end

    api :GET, "/patients/:id/results", "Retrieve the CQM calculation results for a individual patient"
    formats ['json']
    param :id, String, :desc => "Patient ID", :required => true
    example '[{"DENOM":1.0,"NUMER":1.0,"DENEXCEP":0.0,"DENEX":0.0",measure_id":"40280381-3D61-56A7-013E-6224E2AC25F3","nqf_id":"0038","effective_date":1356998340.0,"measure_title":"Childhood Immunization Status",...},...]'
    def results
      log_call LogAction::SEARCH, "API Patients Controller - View individual patient CQM calculation results"

      render :json=> results_with_measure_metadata(@patient.cache_results(params))
    end

    private

    def load_patient
      #qdm_patient_converter = CQM::Converter::QDMPatient.new
      @patient = Patient.find(params[:id])
      #@hds_record = qdm_patient_converter.to_hds(@patient)
      authorize! :read, @patient

      log_call LogAction::READ, "API Patients Controller - View patient information", params[:id]
    end

    def validate_authorization!
      authorize! :read, Patient
    end

    def validate_record_authorizations(records)
      records.each do |record|
        authorize! :read, record
      end    
    end

    def set_filter_params
      @query = {}
      if params[:quality_report_id]
        @quality_report = QualityReport.find(params[:quality_report_id])
        authorize! :read, @quality_report
        @query["provider.npi"] = {"$in" => @quality_report.filters["providers"]}
      elsif current_user.admin?
      else
         @query["provider.npi"] = current_user.npi
      end
      @order = params[:order] || [:last.asc, :first.asc]
    end

    def results_with_measure_metadata(results)
      results.to_a.map do |result|
        hqmf_id = result['extendedData']['hqmf_id']
        #sub_id = result['value']['sub_id']
        measure = Measure.where("hqmf_id" => hqmf_id).only(:title, :description).first
        result['extendedData'].merge(measure_title: measure.title, measure_subtitle: measure.description)
        result
      end
    end
  end
end
