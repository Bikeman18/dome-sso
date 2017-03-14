class OauthCallbacksController < ApplicationController
  include CASino::SessionsHelper
  def create
    auth = request.env['omniauth.auth']
    @identity = Identity.find_for_oauth(auth)
    if signed_in?
      this_user = User.find(current_user.extra_attributes[:guid])
      if @identity.user == this_user
        redirect_to '/profile/bind', notice: '已经绑定过本帐号'
      else
        @identity.user = this_user
        @identity.save
        redirect_to '/profile/bind', notice: '绑定成功'
      end
    else
      if @identity.user.present?
        data = { authenticator: auth.provider, user_data: { username: @identity.user.name, extra_attributes: { guid: @identity.user.id } } }
        sign_in(data)
      else
        session['oauth2-data'] = auth
        flash[:notice] = '请登录或注册，以完成绑定'
        if cookies[:service].present?
          redirect_to '/login?' + URI.encode_www_form('service' => cookies[:service])
        else
          redirect_to '/login'
        end
      end
    end
  end

  private

  def handle_signed_in(tgt, options = {})
    if tgt.awaiting_two_factor_authentication?
      @ticket_granting_ticket = tgt
      render 'casino/sessions/validate_otp'
    else
      if cookies[:service].present?
        params[:service] = cookies[:service]
        begin
          handle_signed_in_with_service(tgt, options)
          return
        rescue Addressable::URI::InvalidURIError => e
          Rails.logger.warn "Service #{params[:service]} not valid: #{e}"
        end
      end
      redirect_to '/sessions', status: :see_other
    end
  end
end
