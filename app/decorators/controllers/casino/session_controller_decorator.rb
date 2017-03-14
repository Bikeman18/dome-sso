CASino::SessionsController.class_eval do
  before_action :set_referrer

  def logout
    sign_out
    session.clear
    @url = params[:url]
    if params[:service].present? && service_allowed?(params[:service])
      redirect_to URI.join(params[:service], "/").to_s, status: :see_other
    end
  end

  def new
    tgt = current_ticket_granting_ticket
    cookies[:service] = params[:service] if params[:service].present?
    return handle_signed_in(tgt) unless params[:renew] || tgt.nil?
    redirect_to(params[:service]) if params[:gateway] && params[:service].present?
  end

  def create
    validation_result = validate_login_credentials(params[:username], params[:password])
    params[:service] = cookies['service'] if !params[:service].present? && cookies['service'].present?
    if !validation_result
      log_failed_login params[:username]
      show_login_error I18n.t('login_credential_acceptor.invalid_login_credentials')
    else
      extra_attributes = validation_result[:user_data][:extra_attributes]
      @user=User.find(extra_attributes[:guid])
      handle_with_oauth2
      if extra_attributes[:confirmed] || extra_attributes[:mobile].present?
        sign_in(validation_result, long_term: params[:rememberMe], credentials_supplied: true)
      else
        @user_name = extra_attributes[:name]
        @email = extra_attributes[:email]
        session[:user_id]=extra_attributes[:guid]
        render "users/before_confirmed"
      end
    end
  end

end
