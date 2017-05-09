class RuleActivity < ActiveRecord::Base
  belongs_to :subscriber
  belongs_to :rule
  belongs_to :ruleable, polymorphic:true
end
