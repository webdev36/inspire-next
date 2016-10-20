class ResponseAction < ActiveRecord::Base
  acts_as_paranoid
  
  attr_accessible :response_text,:action_attributes
  
  has_one :action, as: :actionable  
  accepts_nested_attributes_for :action, allow_destroy:true
  validates_associated :action

  belongs_to :message

  validates :response_text,:presence=>true

  def self.my_csv(poptions={})
    action_columns = Action.column_names.map{|cn|"action_"+cn}
    CSV.generate(poptions) do |csv|
      csv << column_names + action_columns
      all.each do |response_action|
        csv << response_action.attributes.values_at(*column_names) + response_action.action.attributes.values_at(*Action.column_names)
      end
    end
  end

  def self.import(message,file)
    CSV.foreach(file.path,headers:true) do |row|
      response_action = message.response_actions.find_by_id(row["id"]) || message.response_actions.new
      response_action_part={}
      action_part={}
      row.to_hash.each do |k,v|
        if k=~/^action_/
          attr_name = k.sub(/^action_/,'') 
          action_part[attr_name]=v
        else
          response_action_part[k]=v
        end
      end
      action = response_action.build_action if response_action.action.blank?
      action.attributes = action_part.slice(*Action.accessible_attributes)
      response_action.attributes = response_action_part.slice(*accessible_attributes)
      response_action.save!
      action.save!
    end
  end  

end
