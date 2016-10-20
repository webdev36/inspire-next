class HelpController < ApplicationController
  before_filter :save_referrer
  
  def user_show
  end

  def edit_channel
  end

  def index_channels
  end

  def edit_message
  end 

  
  def glossary
  end


  private
  def save_referrer
    session[:referrer_page] = request.referrer unless request.referrer =~/help/
  end
end
