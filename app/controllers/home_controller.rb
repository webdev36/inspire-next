class HomeController < ApplicationController

  def index
  end

  def user_show_help
  end

  def new_web_subscriber
    if request.post?
      status = create_from_web
      if status
        redirect_to thank_you_path
      else
        redirect_to :back
      end
    else
      @channel_group = ChannelGroup.find(params[:channel_group_id])
      redirect_to "/" unless @channel_group.web_signup
    end
  end

  def create_from_web
    channel_group = ChannelGroup.find(params[:channel_group_id])
    if channel_group
      subscriber = Subscriber.find_by_phone_number(params[:mobile_number])
      if subscriber && (subscriber.user_id == channel_group.user_id)
        true
      else
        subscriber = Subscriber.new
        subscriber.user_id = channel_group.user_id
        subscriber.name = "#{params[:first_name]} #{params[:last_name]}"
        subscriber.phone_number = Subscriber.format_phone_number(params[:mobile_number])
        subscriber.additional_attributes = "first_name=#{params[:first_name]};last_name=#{params[:last_name]};#{params[:additional_attributes]}"
        if subscriber.save
          if subscriber.custom_attributes['starting_channel_id']
            channel = Channel.find(subscriber.custom_attributes['starting_channel_id'])
            if channel
              channel.subscribers << subscriber
            end
          end
          true
        else
          false
        end
      end
    else
      false
    end
  end

  def sign_up_success
  end

end
