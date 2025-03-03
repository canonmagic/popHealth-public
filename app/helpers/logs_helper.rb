module LogsHelper
  def time_range_params_plus(url_params_hash)
    url_params_hash[:log_start_date] = params[:log_start_date] if params[:log_start_date]
    url_params_hash[:log_end_date] = params[:log_end_date] if params[:log_end_date]
    url_params_hash[:order] = (@sort_order== :asc ? "desc" : "asc")
    url_params_hash
  end

  def log_failed_authorization(exception)
    user = get_calling_user
    Log.create(:username => user.username,
      :action => LogAction::AUTH, :event => "#{exception.subject.class} - #{exception.action}",
      :description => exception.inspect + (params.nil? ? '' : " Parameters: #{params.except(:utf8, :authenticity_token).inspect}"),
      :medical_record_number => (@patient.nil? ? nil : @patient.medical_record_number),
      :affected_user => (@user.nil? ? nil : @user.username))
  end

  def log_controller_call(action, event, is_sensitive = false)
    log_call action, event, "Controller - " + event, true, false, false, is_sensitive
  end

  def log_api_call(action, event, is_sensitive = false)
    log_call action, event, "API - " + event, true, false, true, is_sensitive
  end

  def log_admin_api_call(action, event, is_sensitive = false)
    log_call action, event, "Admin API - " + event, true, true, true, is_sensitive
  end

  def log_admin_controller_call(action, event, is_sensitive = false)
    log_call action, event, "Admin Controller - " + event, true, true, false, is_sensitive
  end

  def log_call(action, event, patient_identifier = "NULL")
    user = get_calling_user
    parameters = params.nil? ? '' : "Parameters: #{params.except(:action, :controller, :utf8, :authenticity_token, :permitted, :_method, :button, :commit).to_json}"

    PopHealth::Application.config.actions_logger.info "[#{action}, #{event}, #{user.username}, #{patient_identifier}, #{parameters}]"
  end

  def get_errors_for_log(item)
    if item.nil? or item.errors.nil? or item.errors.empty?
      "(none)"
    else
      item.errors.messages
    end
  end

  def get_calling_user
    (defined?(current_user) && current_user) ? current_user : @current_user
  end
end
