class ApplicationController < ActionController::Base
  attr_reader :current_service
  protect_from_forgery with: :null_session

  def send_sms(phone, pin)
    require 'submail'
    submail = Submail.new
    submail.sms(phone, pin).parsed_response
  end

  def handle_with_oauth2
    return nil unless session['oauth2-data'].present?
    @identity = Identity.find_by_uid(session['oauth2-data']['uid'])
    @identity.user = @user
    @identity.save
  end

  rescue_from ActionController::RedirectBackError, with: :redirct_to_default

  protected

  def redirect_to_default
    redirect_to '/'
  end

  def authenticate_request!
    if request.headers['Authorization'].present?
      logger.info request.headers['Authorization']
    else
      logger.info 'no Authorization'
    end
    unless user_id_in_token?
      render json: { errors: ['Not Authenticated'] }, status: :unauthorized
      return
    end

    @current_service = auth_token[:service]

  rescue JWT::VerificationError, JWT::DecodeError
    render json: { errors: ['Not Authenticated'] }, status: :unauthorized
  end

  private

  def set_referrer
    @referrer_host = params[:service] if params[:service].present?
    @referrer_host = cookies['service'] if !@referrer_host.present? && cookies['service'].present?
    session[:referrer] = @referrer_host if @referrer_host && request.host != @referrer_host
  end

  def http_token
    @http_token ||= if request.headers['Authorization'].present?
                      request.headers['Authorization'].split(' ').last
     end
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(http_token)
  end

  def user_id_in_token?
    http_token && auth_token && auth_token[:service].to_s
  end
end
