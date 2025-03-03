require 'measure/loader.rb'
require 'cql_bundle_importer.rb'
require './contrib/measure_dates.rb'
require './app/models/tracker.rb'

module Api

  class LightMeasureSerializer

    include ActiveModel::Serialization  

        attr_accessor :_id, :name, :category, :hqmf_id, :type, :cms_id, :nqf_id, :hqmf_set_id, :hqmf_version_number, :sub_id, :subtitle, :description

  end
  
  class MeasuresController < ApplicationController

    resource_description do
      short 'Measures'
      formats ['json']
      description "This resource allows for the management of clinical quality measures in the popHealth application."
    end

    include PaginationHelper

    include LogsHelper

    before_action :authenticate_user!
    before_action :validate_authorization!
    before_action :set_pagination_params, :only=> :index
    before_action :create_filter , :only => :index
    before_action :update_metadata_params, :only => :update_metadata
    
    
    #api :GET, "/measureslight", "Get a list of measures light"
    param_group :pagination, Api::PatientsController

    def measureslight

      #log_api_call LogAction::READ, "View list of measures"
      
      measures = Measure.where(@filter)
 
      measLight = Array.new

      measures.each do |item|

        p = LightMeasureSerializer.new
        p._id = item._id
        p.name = item.title
        p.category = item.category 
        p.hqmf_id = item.hqmf_id
        p.type = item.reporting_program_type
        p.cms_id = item.cms_id
        p.nqf_id = nil if item[:nqf_id]
        p.hqmf_set_id = item.hqmf_set_id
        p.hqmf_version_number = item.hqmf_version_number
        p.sub_id = nil if item[:sub_id]
        p.subtitle = nil if item[:subtitle]
        p.description = item.description

        measLight << p

      end
     
       render json: measLight

    end

    api :GET, "/measures", "Get a list of measures"

    param_group :pagination, Api::PatientsController
    
    def index

      log_call LogAction::SEARCH, "API Measures Controller - List measures"

      measures = Measure.where(@filter)
      #m = Measure.first
      #Delayed::Worker.logger.info("************** what is M **************")
      #Delayed::Worker.logger.info(m)
      render json: measures
      #paginate(api_measures_url, measures), each_serializer: HealthDataStandards::CQM::MeasureSerializer

    end

    api :GET, "/measures/:id", "Get an individual clinical quality measure"
    param :id, String, :desc => 'The HQMF id for the CQM to calculate', :required => true
    param :sub_id, String, :desc => 'The sub id for the CQM to calculate. This is popHealth specific.', :required => false

    def show
      
      log_call LogAction::READ, "API Measures Controller - View measures"
      
      measure = Measure.where({"hqmf_id" => params[:id]}).first
      render :json => measure
    end

    api :POST, "/measures", "Load a measure into popHealth"
    description "The uploaded measure must be in the popHealth JSON measure format. This will not accept HQMF definitions of measures."
    def create
      authorize! :create, Measure
      bundle_file = File.new(params[:measure_file].tempfile.path)
      importer = CqlBundle::CqlBundleImporter
      @bundle = importer.import(bundle_file, Tracker.new, false)
      # Added by yockler (We can now import bundles using this)
=begin
      measure_details = {
        'type'=>params[:measure_type],
        'episode_of_care'=>params[:calculation_type] == 'episode',
        'category'=> params[:category].empty? ?  "miscellaneous" : params[:category],
        'lower_is_better'=> params[:lower_is_better]
      }
      ret_value = {}
      hqmf_document = Measures::Loader.parse_model(params[:measure_file].tempfile.path)
      if measure_details["episode_of_care"]
        Measures::Loader.save_for_finalization(hqmf_document)
        ret_value= {episode_ids: hqmf_document.specific_occurrence_source_data_criteria().collect{|dc| {id: dc.id, description: dc.description}},
                    hqmf_id: hqmf_document.hqmf_id,
                    vsac_username: params[:vsac_username],
                    vsac_password: params[:vsac_password],
                    category: measure_details["category"],
                    lower_is_better: measure_details[:lower_is_better],
                    hqmf_document: hqmf_document
                  }
      else
        Measures::Loader.generate_measures(hqmf_document,params[:vsac_username],params[:vsac_password],measure_details)
      end
      #log_api_call LogAction::UPDATE, "Loaded measure"
      render json: ret_value
=end
      rescue => e
        #log_api_call LogAction::UPDATE, "Failed to load measure, with error #{e}"
        render text: e.to_s, status: 500
    end

    api :DELETE, '/measures/:id', "Remove a clinical quality measure from popHealth"
    param :id, String, :desc => 'The HQMF id for the CQM to calculate', :required => true
    description "Removes the measure from popHealth. It also removes any calculations for that measure."
    def destroy
      authorize! :delete, Measure
      measure = Measure.where({"hqmf_id" => params[:id]})

      if(measure)
        log_call LogAction::DELETE, "API Measures Controller - Delete measure"

        #delete all of the pateint and query cache entries for the measure
        #HealthDataStandards::CQM::PatientCache.where({"value.measure_id" => params[:id]}).destroy
        #HealthDataStandards::CQM::QueryCache.where({"measure_id" => params[:id]}).destroy
        measure.destroy
        render :status=>204, :text=>""
      else
        render :status=>404, :text=>"Not found"
      end

    end

    def update_metadata
      authorize! :update, Measure

      measures = Measure.where({ hqmf_id: params[:hqmf_id]})

      log_call LogAction::UPDATE, "API Measures Controller - Update measures metadata"

      measures.each do |m|
        m.update_attributes(params[:measure])
        m.save
      end

      render json:  measures,  each_serializer: HealthDataStandards::CQM::MeasureSerializer
      rescue => e
        render text: e.to_s, status: 500
    end

    def finalize

      measure_details = {
          'episode_ids'=>params[:episode_ids],
          'category' => params[:category],
          'measure_type' => params[:measure_type],
          'lower_is_better' => params[:lower_is_better]

       }

      Measures::Loader.finalize_measure(params[:hqmf_id],params[:vsac_username],params[:vsac_password],measure_details)

      measure = Measure.where({hqmf_id: params[:hqmf_id]}).first

      if(measure)
        log_call LogAction::UPDATE, "API Measures Controller - Finalize measure"

        render json: measure, serializer: HealthDataStandards::CQM::MeasureSerializer
      else
        render text: "Measure not found", status: 404
      end

      rescue => e
        render text: e.to_s, status: 500
      end
    end

  private

    def validate_authorization!
      authorize! :read, Measure
    end

    def create_filter
      measure_ids = params[:measure_ids]
      @filter = measure_ids.nil? || measure_ids.empty? ? {} : {:hqmf_id.in => measure_ids}
    end

    def update
      params[:measure][:lower_is_better] = nil if params[:measure][:lower_is_better].blank?
    end

  end
end
