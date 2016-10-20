class ChannelGroupsController < ApplicationController
  before_filter :load_channel_group, :except => [:create_from_web]
  skip_before_filter :load_channel_group, :only => [:new,:create,:remove_channel]
  before_filter :load_user, :only =>[:new,:create]
  before_filter :load_channel, :only => [:remove_channel]

  def show
    @channels = @channel_group.channels.page(params[:channels_page]).per_page(10) if @channel_group
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @channel_group }
    end
  end

  def new
    @channel_group = @user.channel_groups.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @channel_group }
    end
  end

  def edit
  end

  def create
    @channel_group = @user.channel_groups.new(params[:channel_group])

    respond_to do |format|
      if @channel_group.save
        format.html { redirect_to @channel_group, notice: 'Channel group was successfully created.' }
        format.json { render json: @channel_group, status: :created, location: @channel_group }
      else
        format.html { render action: "new" }
        format.json { render json: @channel_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @channel_group.update_attributes(params[:channel_group])
        format.html { redirect_to @channel_group, notice: 'Channel group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @channel_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @channel_group.destroy

    respond_to do |format|
      format.html { redirect_to user_url(@user) }
      format.json { head :no_content }
    end
  end

  def remove_channel
    already_member = @channel_group.channels.where(id:@channel.id).first
    notice = 'Channel not currently part of this group. No changes done'
    if already_member
      @channel_group.channels.delete @channel
      @channel.destroy
      notice='Channel removed from group'
    end
    respond_to do |format|
      format.html { redirect_to channel_group_path(@channel_group), notice: notice }
      format.json { render json: @channel_group.channels, location: [@channel_group] }
    end
  end

  def messages_report
    respond_to do |format|
      format.csv {send_data @channel_group.messages_report}
    end
  end

  def new_web_subscriber
  end

private

  def load_user
    authenticate_user!
    @user = current_user
  end

  def load_channel_group
    authenticate_user!
    @user = current_user
    @channel_group = @user.channel_groups.find(params[:id])
    redirect_to(root_url,alert:'Access Denied') unless @channel_group
  rescue
      redirect_to(root_url,alert:'Access Denied')
  end

  def load_channel
    authenticate_user!
    @user = current_user
    @channel_group = @user.channel_groups.find(params[:channel_group_id])
    redirect_to(root_url,alert:'Access Denied') unless @channel_group
    @channel = @user.channels.find(params[:id])
    redirect_to(root_url,alert:'Access Denied') unless @channel
  rescue
    redirect_to(root_url,alert:'Access Denied')
  end



end
