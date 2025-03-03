class TeamsController < ApplicationController
  include LogsHelper

  before_action :authenticate_user!

  before_action :set_team, only: [:show, :edit, :update, :destroy]
  authorize_resource
  # GET /teams
  def index
    log_call LogAction::SEARCH, "Teams Controller - List teams"

    @teams = @current_user.teams
    validate_authorization!(@teams)

    #Code added by Jose Melendez (10/14/2023)
    #This code snippet makes the 'providers' variable available in index.html.erb to open a popup with the data.

    if current_user.admin? || APP_CONFIG['use_opml_structure']
    @providers = Provider.all
      else
    @providers = Provider.where(parent_id: current_user.try(:practice).try(:provider_id))
    end

    
  end

  # GET /teams/1
  def show

    log_call LogAction::READ, "Teams Controller - View team"

    @providers = @team.providers.map do |id| 
      provider = Provider.find(id)
      provider unless cannot? :read, provider 
    end
  end

  # GET /teams/new
  def new

    @providers = Provider.all
    if current_user.admin? || APP_CONFIG['use_opml_structure']
      @providers = Provider.all
    else
      @providers = Provider.where(parent_id: current_user.try(:practice).try(:provider_id))
    end
  end

  # POST 
  def create

    name = params[:name]
    provider_ids = params[:provider_ids]

    if name.strip.length > 0  && !provider_ids.blank?
      @team = Team.create(:name => params[:name])
      provider_ids.each do |prov_id|
        @team.providers << prov_id
      end

      log_call LogAction::CREATE, "Teams Controller - Create new team"

      @team.user_id = @current_user._id
      @team.save!

      current_user.teams << @team
      current_user.save!
      redirect_to @team
    else
      redirect_to :action => :new
    end
  end
  
  def create_default
    if current_user.practice
      log_call LogAction::CREATE, "Teams Controller - Create new team"

      @team = Team.find_or_create_by(:name => "All Providers", user_id: current_user.id)
      @team.providers = []

      Provider.where(parent_id: current_user.practice.provider_id).each do |prov|
        @team.providers << prov.id.to_s
      end

      unless current_user.teams.include?(@team)
        current_user.teams << @team
        current_user.save!
      end
    else
      log_page_view "Unable to create default team, user practice is not set. #{params.inspect}"
    end

    redirect_to :action => :index

  end

  # post /teams/1
  def update
    #Add Jose Melendez, el nombre del equipo esta anidado al parametro team
    name = params[:team][:name]
    #name = params[:name]
    provider_ids = params[:provider_ids]

    if name.strip.length > 0  && !provider_ids.blank?
      @team.name = name
      @team.providers.clear

      provider_ids.each do |prov_id|
        @team.providers << prov_id
      end

      log_call LogAction::UPDATE, "Teams Controller - Update team"
      @team.save!
    end
    
    redirect_to @team
  end

  # GET /teams/1/edit
  def edit

    if current_user.admin? || APP_CONFIG['use_opml_structure']
      @providers = Provider.all
    else
      @providers = Provider.where(parent_id: current_user.practice.provider_id)
    end      

  end

  # DELETE /teams/1
  def destroy
    @current_user.teams.delete(@team)
    @current_user.save!
    
    log_call LogAction::DELETE, "Teams Controller - Delete team"
    @team.destroy

    redirect_to teams_url, notice: 'Team was successfully destroyed.'

  end

  #Add Jose Melendez: poder obtener la información del team por el ID

  def show_by_id

    @team = Team.find(params[:id])

    log_call LogAction::READ, "Teams Controller - View team"
    validate_authorization!([@team])

    render json: @team

  end

  #

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
      validate_authorization!([@team])
    end
   
    def validate_authorization!(teams)
      teams.each do |team|
        authorize! :manage, team
      end
    end
end
