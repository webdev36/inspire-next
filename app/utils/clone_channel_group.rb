# this clones a channel group creating new channels for either the same
# or a different user
class CloneChannelGroup
  attr_accessor :tparty_keyword, :new_owner_id, :old_channel_group_id

  def self.copy(old_channel_group_id, new_owner_id, tparty_keyword = nil)
    raise "need tparty keyword" unless tparty_keyword
    helper = new(old_channel_group_id, new_owner_id, tparty_keyword)
    helper.copy_channel_group
  end

  def initialize(old_channel_group_id, new_owner_id, tparty_keyword = nil)
    @old_channel_group_id = old_channel_group_id
    @new_owner_id = new_owner_id
    @tparty_keyword = tparty_keyword
  end

  def run
    copy_channel_group
  end

  def user
    @user ||= User.find(new_owner_id)
  end

  def old_channel_group
    @old_channel_group ||= ChannelGroup.find(@old_channel_group_id)
  end

  def old_channels
    old_channel_group.channels
  end

  def copy_channel_group
    new_channel_group
    old_channel_group.channels.each do |old_channel|
      new_channel = create_new_channel_from(old_channel)
      cc_helper = CopyChannel.new(old_channel.id, new_channel.id)
      cc_helper.copy_messages
      puts "Wrote #{new_channel.id}-#{new_channel.messages.length} messages"
    end
  end

  def create_new_channel_from(old_channel)
    new_channel = Channel.new
    old_channel.attributes.keys.each do |key|
      next if channel_attributes_to_remove.include?(key)
      new_channel[key] = old_channel[key]
    end
    new_channel.user_id = user.id
    new_channel.channel_group_id = new_channel_group.id
    new_channel.tparty_keyword = @tparty_keyword
    if new_channel.save
      new_channel
    else
      binding.pry
      raise RuntimeError.new 'Unable to save newly creating channel.'
    end
  end

  def new_channel_group
    @new_channel_group ||= begin
      ncg = user.channel_groups.new
      old_channel_group.attributes.keys.each do |key|
        next if channel_group_attributes_to_remove.include?(key)
        ncg[key] = old_channel_group[key]
      end
      ncg.user_id = user.id
      ncg.tparty_keyword = @tparty_keyword
      if ncg.save
        ncg
      else
        raise StandardError.new(ncg.errors.messages.to_s)
      end
    end
  end

  def channel_attributes_to_remove
    %w( id user_id tparty_keyword channel_group_id created_at updated_at moderator_emails )
  end

  def channel_group_attributes_to_remove
    %w( id user_id tparty_keyword created_at updated_at moderator_emails )
  end



end
