class PracticesController < ApplicationController
  #add Jose Melendez, 05/12/2023
  before_action :set_practice, only: [:edit, :update, :destroy]
  include LogsHelper 
  include ApplicationHelper

  authorize_resource
  before_action :authenticate_user!  
 	before_action :validate_authorization

  # GET /practice
  # GET /practice.json
  
  def validate_authorization
  	authorize! :admin, :practice
  end
  
  def index
    log_call LogAction::SEARCH, "Practices Controller - List practices"

    @practices = Practice.all
    #Add Jose Melendez: Create a variable that counts the practices that have an associated provider_id
    @practices_with_provider = Practice.where(:provider_id.ne => nil).count
    #
		@practice = Practice.new
		@users = User.all.map {|user| [user.username, user.id]}
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @practice }
    end
  end

  # GET /practices/1
  # GET /practices/1.json
  def show
    @practice = Practice.find(params[:id])
    @users = User.all.map {|user| [user.username, user.id]}

    if @practice.nil?
      respond_to do |format|
        format.html { redirect_to practices_path, notice: 'A practice with that identifier could not be found.' }
        format.json { render json: @practice, status: :not_found }
      end
    else
      log_call LogAction::READ, "Practices Controller - View practice"

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @practice }
      end
    end
  end
  
  # POST /practices
  # POST /practices.json
  def create
    log_call LogAction::CREATE, "Practices Controller - Create new practice"
  begin
    @practice = Practice.new(name: params[:practice]['name'], organization: params[:practice]['organization'], address: params[:practice]['address'])
    @practice.save
    if @practice.save
      identifier = CDAIdentifier.new(:root => "Organization", :extension => @practice.organization)
      provider = Provider.new(:given_name => @practice.name)
      provider.cda_identifiers << identifier
      #TODO
      # provider.parent = Provider.root
      provider.save
      @practice.provider = provider
      if params[:user] != ''
        user = User.find(params[:user])
        @practice.users << user
        user.save
      end
    end
    respond_to do |format|
      if @practice.save
        format.html { redirect_to practices_path, notice: 'Practice was successfully created.' }
        format.json { render json: @practice, status: :created, location: @practice }
      else
        format.html { redirect_to practices_path }
        format.json { render json: @practice.errors, status: :unprocessable_entity }
      end
    end
  rescue Exception => e
    puts "Error creating practice"
    puts e.message
  end
  end

  # PUT /practices
  # PUT /practices.json

  #Modify by Jose Melendez, 05/12/2023
  def update
    @practice = Practice.find(params[:id])

    if @practice
      log_call LogAction::UPDATE, "Practices Controller - Practices Controller - Update practice"

      if @practice.update(practice_params)
        respond_to do |format|
          format.html { redirect_to practices_path, notice: 'Practice was successfully updated.' }
          format.json { render json: @practice, status: :created, location: @practice }
        end
      else
        respond_to do |format|
          format.html { redirect_to practices_path }
          format.json { render json: @practice.errors, status: :unprocessable_entity }
        end
      end
    else
    end
  end


  # def update
  #   @practice = Practice.find(params[:id])
  #   @practice.update_attributes(params[:practice]) unless @practice.nil?

  #   respond_to do |format|
  #     if @practice.save
  #       log_controller_call LogAction::UPDATE, "Update practice"
  #       format.html { redirect_to practices_path, notice: 'Practice was successfully updated.' }
  #       format.json { render json: @practice, status: :created, location: @practice }
  #     else
  #       log_controller_call LogAction::UPDATE, "Failed to update practice, with errors #{get_errors_for_log(@practice)}"
  #       format.html { redirect_to practices_path }
  #       format.json { render json: @practice.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  def remove_patients
    @practice = Practice.find(params[:id])

    if(@practice)
      log_call LogAction::DELETE, "Practices Controller - Remove all patients from practice"

      remove_patients_from_practice(params[:id]) #see ApplicationHelper module 
      respond_to do |format|
        format.html { redirect_to :action => :index }
      end
    else
      format.html { redirect_to practices_path }
      format.json { render json: @practice.errors, status: :unprocessable_entity }
    end

  end
  
  def remove_providers
    @practice = Practice.find(params[:id])

    if(@practice)
      log_call LogAction::DELETE, "Practices Controller - Remove all providers from practice"

      Provider.where(parent_id: practice.provider.id).delete
    
      respond_to do |format|
        format.html { redirect_to :action => :index }
      end
    else
      format.html { redirect_to practices_path }
      format.json { render json: @practice.errors, status: :unprocessable_entity }
    end

  end
  
  # DELETE /practices/1
  # DELETE /practices/1.json
  def destroy
    @practice = Practice.find(params[:id])

    if(@practice)
      log_call LogAction::DELETE, "Practices Controller - Delete practice"
      
      if @practice.provider
        id = @practice.provider.id

        @current_user.teams.each do |tm|
          tm.providers.delete(id.to_s)
          tm.save!
        end

        @current_user.save!
        @practice.provider.delete
      end

      @practice.destroy
  
      respond_to do |format|
        format.html { redirect_to :action => :index}
      end
    else
      format.html { redirect_to practices_path }
      format.json { render json: @practice.errors, status: :unprocessable_entity }
    end

  end

private

def practice_params
  params.require(:practice).permit('name', 'organization', 'address')
end

#add Jose Melendez, 05/12/2023
def set_practice
  log_call LogAction::READ, "Practices Controller - View practice"

  @practice = Practice.find(params[:id])
end

end

