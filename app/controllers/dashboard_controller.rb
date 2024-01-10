class DashboardController < ApplicationController
    before_action :authenticate_user!

    Model = CQM::Measure

    def index

        if params[:_id].present?

            provider_id = params[:_id]

        else

        end

        @categories_cms_ids = load_categories_pophealth

    end

    def check_authorization
        @provider = Provider.find(params[:id])
        auth = (can? :read, @provider) ? true : false
        render :json => auth.as_json
    end

    def measure_result

        patient_id = params[:id]

    end

    def patient_details
    end

    def set_reporting_period

        user = User.where(username: params[:username]).first
        unless params[:effective_start_date].blank? || params[:effective_date].blank?
            month, day, year = params[:effective_start_date].split('/')
            user.effective_start_date = Time.gm(year.to_i, month.to_i, day.to_i).to_i
            month, day, year = params[:effective_date].split('/')
            user.effective_date = Time.gm(year.to_i, month.to_i, day.to_i).to_i
        user.save! 
        end
        render :json => :set_reporting_period, status: 200

    end

    private

    def load_categories_pophealth

        categories_cms_ids = {}

        measures = Model.pluck(:id, :cms_id, :category, :title, :hqmf_id)

        measures.each do |measure|

            id, cms_id, category, title, hqmf_id = measure

            if categories_cms_ids.key?(category)

                categories_cms_ids[category] << { cms_id: cms_id, title: title, id: id, hqmf_id: hqmf_id }

            else

                categories_cms_ids[category] = [{ cms_id: cms_id, title: title, id: id, hqmf_id: hqmf_id }]
            
            end

        end

        categories_cms_ids

    end

    def validate_authorization!
        authorize! :read, HealthDataStandards::CQM::Measure
    end

end
