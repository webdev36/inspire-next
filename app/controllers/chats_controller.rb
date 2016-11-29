class ChatsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_chatroom

  def create
    chat = @chatroom.chats.new(chat_params)
    chat.chatter = current_user
    if chat.save
      redirect_to @chatroom
    end
  end

  private

    def set_chatroom
      @chatroom = current_user.chatrooms.find(params[:chatroom_id])
    end

    def chat_params
      params.require(:chat).permit(:body)
    end
end
