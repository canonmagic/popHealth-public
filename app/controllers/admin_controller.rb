require 'import_archive_job'
require 'fileutils'

class AdminController < ApplicationController
  include LogsHelper

  before_action :authenticate_user!
  before_action :validate_authorization!

  def patients
    log_call LogAction::SEARCH, "Admin Controller - View patients"

    @patient_count = Patient.count
    @query_cache_count = QualityReport.count
    @patient_cache_count = IndividualResult.count
    @provider_count = Provider.ne('cda_identifiers.root' => "Organization").count
    @practice_count = Practice.count
    @practices = Practice.asc(:name).map {|org| [org.name, org.id]}
  end

  def jobs
    log_call LogAction::SEARCH, "Admin Controller - View jobs"

    @job_count = Delayed::Job.count
    @patient_job_count = Delayed::Job.where(queue: "patient_import").count
    @calculation_job_count = Delayed::Job.where(queue: "calculation").count
  end

  def user_profile
    @user = User.find(params[:id])

    log_call LogAction::READ, "Admin Controller - View user profile"

    @practices = Practice.asc(:name).map {|org| [org.name, org.id]}
    @practice_pvs = Provider.by_npi(@user.npi).map {|pv| [pv.parent.practice.name + " - " + pv.full_name, pv.id]}
  end

  #Add Jose Melendez. Modify: response json format
  def set_user_practice
    @user = User.find(params[:user])

    if(@user)
      log_call LogAction::UPDATE, "Admin Controller - Modify user practice"

      if params[:practice].present?
          @user.practice = Practice.find(params[:practice])
      else
          @user.practice = nil
      end
      
      if @user.save
          render json: { success: true, message: 'Practice changed successfully' }
      else
          render json: { success: false, message: 'Failed to change practice. Please try again.' }, status: :unprocessable_entity
      end
    else
      render json: { success: false, message: 'Failed to change practice. Please try again.' }, status: :unprocessable_entity
    end
  end

  def set_user_practice_provider
    log_call LogAction::UPDATE, "Admin Controller - Modify user provider"

    @user = User.find(params[:user])
    @user.provider_id = (params[:provider].present?)? Provider.find(params[:provider]).id : nil
    @user.save

    redirect_to action: 'user_profile', :id => params[:user]
  end

  def remove_patients
    log_call LogAction::DELETE, "Admin Controller - Remove all patients"

    Patient.delete_all

    redirect_to action: 'patients'
  end

  def remove_jobs
    log_call LogAction::DELETE, "Admin Controller - Remove all jobs"

    Delayed::Job.delete_all

    redirect_to action: 'jobs'
  end

  def remove_caches
    log_call LogAction::DELETE, "Admin Controller - Clear patients cache"

    QualityReport.delete_all
    IndividualResult.delete_all
    Mongoid.default_client["rollup_buffer"].drop()

    redirect_to action: 'patients'
  end

  def remove_providers
    log_call LogAction::DELETE, "Admin Controller - Remove all providers"

    Provider.ne('cda_identifiers.root' => "Organization").delete
    
    Team.update_all(providers: [])
    
    redirect_to action: 'patients'
  end

  def remove_all
    log_call LogAction::DELETE, "Admin Controller - Clear all caches"

    # Remove patients
    Patient.delete_all

    # Remove providers
    Provider.ne('cda_identifiers.root' => "Organization").delete
    Team.update_all(providers: [])

    # Remove caches
    QualityReport.delete_all
    IndividualResult.delete_all
    Mongoid.default_client["rollup_buffer"].drop()

    redirect_to action: 'patients'
  end

  def upload_patients
    log_call LogAction::IMPORT, "Admin Controller - Import QRDA CAT I ZIP file"

    file = params[:file]
    practice = params[:practice]
    
    FileUtils.mkdir_p(File.join(Dir.pwd, "tmp/import"))
    file_location = File.join(Dir.pwd, "tmp/import")
    file_name = "patient_upload" + Time.now.to_i.to_s + rand(1000).to_s

    temp_file = File.new(file_location + "/" + file_name, "w")
    File.open(temp_file.path, "wb") { |f| f.write(file.read) }
    Delayed::Job.enqueue(ImportArchiveJob.new({'practice' => practice, 'file' => temp_file,'user' => current_user}),:queue=>:patient_import)

    redirect_to action: 'patients'
  end

  def users
    log_call LogAction::SEARCH, "Admin Controller - List user profiles"

    @users = User.all.ordered_by_username
    @practices = Practice.asc(:name).map {|org| [org.name, org.id]}

    unless APP_CONFIG['use_opml_structure']
      @practice_providers = Provider.ne('cda_identifiers.root' => "Organization").asc(:given_name).map {|pv| [pv.full_name, pv.id]}
    end
    
  end

  def promote
    @user = User.by_username(params[:username])

    if(@user)
      log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - User promoted"

      toggle_privilidges(params[:username], params[:role], :promote)
    else
      render json: { status: 'error', message: 'User not found' }
    end

  end

  def demote
    @user = User.by_username(params[:username])

    if(@user)
      log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - User demoted"

      toggle_privilidges(params[:username], params[:role], :demote)
    else
      render json: { status: 'error', message: 'User not found' }
    end

  end

  #Change by Jose Melendez, 06/12/2023
  # Switching from render :text (deprecated in Rails 6) to render plain:
  # for compatibility with the latest versions of Rails.
  # JSON provides a clearer and extensible data structure, enhancing code readability and maintainability.

  def disable
      @user = User.by_username(params[:username])
      disabled = params[:disabled].to_i == 1

      if @user
          @user.update_attribute(:disabled, disabled)

          if disabled
            log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - Enable user"
            render json: { status: 'success', message: 'User disabled', action: 'enable' }
          else
            log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - Disable user"
            render json: { status: 'success', message: 'User enabled', action: 'disable' }
          end
      else
          render json: { status: 'error', message: 'User not found' }
      end

  end


  def approve
    @user = User.where(:username => params[:username]).first

    if @user
      log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - User enabled"
      @user.update_attribute(:approved, true)
      render :text => "true"
    else
      render :text => "User not found"
    end

  end

  def update_npi
    @user = User.by_username(params[:username]);

    if @user
      log_call LogAction::UPDATE, "Admin Controller - Update user NPI"
      @user.update_attribute(:npi, params[:npi]);
      render :text => "true"
    else
      render :text => "false"
    end

  end

  def delete_user
    @user = User.find(params[:id])

    if @user
      if User.count == 1
        redirect_to :action => :users, notice: "Cannot remove sole user"
      elsif @user.admin? 
        redirect_to :action => :users, notice: "Cannot remove administrator"
      else
        log_call LogAction::DELETE, "Admin Controller - Delete user"
  
        @user.destroy
        redirect_to :action => :users
      end
    else
      redirect_to :action => :users, notice: "User not found"
    end
  end

  private


  #Change by Jose Melendez, 06/12/2023
  # Switching from render :text (deprecated in Rails 6) to render plain:
  # for compatibility with the latest versions of Rails.
  # JSON provides a clearer and extensible data structure, enhancing code readability and maintainability.

  def toggle_privilidges(username, role, direction)
    @user = User.by_username(username)

    if @user
        if direction == :promote
          log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - User promoted"
          @user.update_attribute(role, true)
          render json: { status: 'success', message: 'User promoted', action: 'revoke' }
        else
          log_call LogAction::CHANGE_USER_PRIVILEGIES, "Admin Controller - User demoted"
          @user.update_attribute(role, false)
          render json: { status: 'success', message: 'User demoted', action: 'grant' }
        end
    else
        render json: { status: 'error', message: 'User not found' }
    end

  end


  def validate_authorization!
    authorize! :admin, :users
  end
end
