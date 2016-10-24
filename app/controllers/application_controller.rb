class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(user)
    user_path(user)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password, :remember_me])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation])
  end

end
