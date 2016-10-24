module Admin
  class HomeController < ApplicationController
    before_action :load_user

    def index
      respond_to do |format|
        format.html
        format.json { render json: @channels }
      end
    end

  private

    def load_user
      authenticate_user!
      @user = current_user
    end

  end
end
