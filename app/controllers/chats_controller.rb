class ChatsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_chatroom

  def create
    chat = current_user.chats.new(chat_params)
    @chatroom.chats << chat
    redirect_to @chatroom
  end

  private

    def set_chatroom
      @chatroom = current_user.chatrooms.find(params[:chatroom_id])
    end

    def chat_params
      params.require(:chat).permit(:body)
    end
end
