class Api::UsersController < ApplicationController
  respond_to :json
  before_action :authenticate_request!

  def show
    @user = User.find(params[:id])
    if params[:profile] == 'true'
      respond_with @user, valid_keys: set_valid_keys('r')
    else
      respond_with @user, serializer: BaseUserSerializer
    end
  end

  def update
    @user_extra = User.find(params[:id]).user_extra
    if @user_extra.update_attribute(:info, @user_extra.info.merge(params[:profile].to_hash.slice(*set_valid_keys('w'))))
      head :no_content
    else
      render json: @user_extra.errors, status: :unprocessable_entity
    end
  end

  private

  def set_valid_keys(rw)
    @service_permission = ServicePermission.find_by_name(@current_service)
    if @service_permission.present? && @service_permission.key_permissions.present?
      @key_permissions = @service_permission.key_permissions
      if rw == 'w'
        return @key_permissions.select { |_k, v| v == 2 }.keys
      else
        return @key_permissions.select { |_k, v| v > 0 }.keys
      end
    end
  end

end
