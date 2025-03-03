
module Api
  class ProvidersController < ApplicationController
    resource_description do
      short 'Providers'
      formats ['json']
      description <<-PRCDESC
        This resource allows for the management of providers in popHealth

        popHealth assumes that providers are in a hierarchy. This resource allows users
        to see the hierarchy of providers
      PRCDESC
    end
    include PaginationHelper
    include LogsHelper
    # load resource must be before authorize resource
    # load_and_authorize_resource except: %w{index create new search}
    authorize_resource
    respond_to :json
    before_action :authenticate_user!

    api :GET, "/providers", "Get a list of providers. Returns all providers that the user has access to."
    param_group :pagination, Api::PatientsController
    def index

      log_call LogAction::SEARCH, "API Providers Controller - List providers"

      if APP_CONFIG['use_opml_structure']
        @providers = Provider.all
        authorize_providers(@providers)
      elsif current_user.admin?
        providers = Provider.all
        authorize_providers(providers)
        @providers = providers.map do |p|
          p_json = p.as_json
          p_json[:practice] = p.try(:parent).try(:practice).try(:name) || p.try(:practice).try(:name)
          p_json
        end
      else
        if current_user.practice
          my_prid=current_user.practice.provider_id
          other_practices = Practice.only(:provider_id).all.map{|p| p[:provider_id]}.reject{|id| id==my_prid}
          @providers = Provider.or({parent_id: my_prid},
                       {_id: my_prid}).reject{|p| other_practices.include?(p[:_id])}
          authorize_providers(@providers)
        end
      end

      render json: @providers
    end

    api :GET, "/providers/:id", "Get an individual provider"
    param :id, String, :desc => "Provider ID", :required => true
    description <<-SDESC
      This will return an individual provider. It will include the id and name of its parent, if it
      has a parent. Children providers one level deep will be included in the children property
      if any children for this provider exist.
    SDESC
    def show
      @provider = Provider.find(params[:id])
      
      if($provider)
        log_call LogAction::READ, "API Providers Controller - View provider"
        
        if can? :read, @provider
          provider_json = @provider.as_json
          provider_json[:parent] = Provider.find(@provider.parent_id) if @provider.parent_id
          provider_json[:children] = @provider.children if @provider.children.present?
          provider_json[:patient_count] = @provider.practice.cqmPatient.count if @provider.practice
        else
          provider_json = {}
        end

        render json: provider_json
      else
        render text: "Provider not found", status: 404
      end
    end

    api :POST, "/providers", "Create a new provider"
    def create
      log_call LogAction::CREATE, "API Providers Controller - Create new provider"

      @provider = Provider.create(params[:provider].to_unsafe_hash)

      render json: @provider
    end

    api :PUT, "/providers/:id", "Update a provider"
    param :id, String, :desc => "Provider ID", :required => true
    def update
      log_call LogAction::UPDATE, "API Providers Controller - Update provider"

      @provider.update_attributes!(params[:provider])
      render json: @provider
    end

    def new
      render json: Provider.new
    end

    api :DELETE, "/providers/:id", "Remove an individual provider"
    param :id, String, :desc => "Provider ID", :required => true
    def destroy
      log_call LogAction::DELETE, "API Providers Controller - Delete provider"

      @provider.destroy

      render json: nil, status: 204
    end

    # ruby routing is bizarre
    api :GET, "/providers/search?npi=:npi&tin=:tin&taxonomy=:taxonomy&address=:address", "Search for provider by partial NPI/TIN/Addresss"
    param :npi, String, :desc => "National Provider Identifier", :required => false
    param :tin, String, :desc => "Tax Information Number", :required => false
    param :taxonomy, String, :desc => "Taxonomy Code", :required => false
    param :address, String, :desc => "Practice address piece", :required => false
    def search
      log_call LogAction::SEARCH, "API Providers Controller - Search provider"

      if ! params[:npi].nil?
        providers = Provider.all({"cda_identifiers" => {"$elemMatch" => {'root' =>"2.16.840.1.113883.4.6", "extension" => /#{params[:npi]}/i }}})
        render json: providers.map {|p| { id: p.id, name: "#{p.full_name} (#{p.npi})", parent_id: p.parent_id} }
      elsif ! params[:tin].nil?
        providers = Provider.all({"cda_identifiers" => {"$elemMatch" => {'root' =>"2.16.840.1.113883.4.2", "extension" => /#{params[:tin]}/i }}})
        render json: providers.map {|p| { id: p.id, name: "#{p.full_name} (#{p.tin})", parent_id: p.parent_id} }
      elsif !params[:taxonomy].nil?
        providers = Provider.any_of({"specialty" => /.*#{params[:taxonomy]}.*/})
        taxonomies = [];
        providers.each do |p|
          if(!taxonomies.include?(p.specialty))
             taxonomies.push(p.specialty)
          end
        end
        render json: taxonomies.each_with_index.map {|p, idx| { "_id": idx, "code": p, "code_system_oid": "2.16.840.1.113762.1.4.1026.23", "display_name": p} }
      elsif !params[:address].nil?
        # should be able to automate with something like Provider.fields.keys['<addresses_no>'].keys, but
        # the Provider model in no way matches the current db collection, so spell it all out.
        x=params[:address]
        query={"addresses" => {"$elemMatch" => {"$or":[
            {"city":/#{x}/i},
            {"street":/#{x}/i},
            {"state":/#{x}/i},
            {"zip":/#{x}/i},
            {"country":/#{x}/i}
        ]}}}
        providers = Provider.all(query)
        render json: providers.map {|p| { id: p.id, name: "#{p.full_name} (#{p.addresses})", parent_id: p.parent_id} }
      end
    end

    private

    def authorize_providers(providers)
      providers.each do |p|
        authorize! :read, p
      end
    end
  end
end
