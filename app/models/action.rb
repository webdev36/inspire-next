# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

class Action < ActiveRecord::Base
  include ActionView::Helpers
  acts_as_paranoid
  
  attr_accessible :type,:as_text,:to_channel,:message_to_send
  belongs_to :actionable, polymorphic:true


  validates :type,:presence=>true,:inclusion=>{:in=>['SwitchChannelAction','SendMessageAction']}
  #validates :as_text,:presence=>true

  @child_classes = []

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Action.model_name
      end
    end
    @child_classes << child
    super
  end

  def self.child_classes
    @child_classes
  end  

  def execute(opts={})
    raise NotImplementedError
  end

  def type_abbr
    raise NotImplementedError
  end  

  def description
    raise NotImplementedError
  end

  #HACK. These are subclass attributes. This should not have been
  #STI
  def to_channel=(val)
    @to_channel = val
  end

  def to_channel
    @to_channel || get_to_channel_from_text
  end
  
  def get_to_channel_from_text
    if as_text
      md = as_text.match(/^Switch channel to (\d+)$/)
      md[1] if md    
    else
      nil
    end
  end

  def message_to_send=(val)
    @message_to_send = val
  end

  def message_to_send
    @message_to_send || get_message_to_send_from_text
  end

  def get_message_to_send_from_text
    if as_text
      md = as_text.match(/^Send message (\d+)$/)
      md[1] if md
    else
      nil
    end
  end


  class << self
    def new_with_cast(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && type.length > 0 && (klass = type.constantize) != self
        raise "Cast failed"  unless klass <= self
        return klass.new(*attributes, &block)
      end
      new_without_cast(*attributes, &block)
    end
    alias_method_chain :new, :cast
  end
end 
