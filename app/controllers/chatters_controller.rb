class ChattersController < ApplicationController
  before_action :set_chatroom
  before_action :load_user, only: %i(new create update index)
  before_action :set_subscriber, only: %i(add_to_chatroom remove_from_chatroom)

  # GET /chatrooms
  def index
    @subscribers = @chatroom.subscribers
    @subscribed_ids = @subscribers.map(&:id)
    @subscribers_not_in_chat = @user.subscribers.select { |subx| !@subscribed_ids.include?(subx.id) }
  end

  # POST /chatrooms
  def add_to_chatroom
    if @chatroom && @subscriber
       @chatroom.subscribers << @subscriber
    end
    redirect_to :back, notice: 'Subscriber was added to chatroom'
  end

  def remove_from_chatroom
    if @chatroom && @subscriber
      @chatroom.subscribers.delete(@subscriber)
    end
    redirect_to :back, notice: 'Subscriber was removed from chatroom'
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chatroom
      @chatroom = Chatroom.find(params[:chatroom_id])
    end

    # Only allow a trusted parameter "white list" through.
    def chatroom_params
      params.require(:chatroom).permit(:name)
    end

    def set_subscriber
      @subscriber = Subscriber.find(params[:subscriber_id])
    end
end
