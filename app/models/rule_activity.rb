class RuleActivity < ActiveRecord::Base
  belongs_to :subscriber
  belongs_to :rule
end
