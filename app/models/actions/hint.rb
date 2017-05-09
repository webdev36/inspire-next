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

class Hint < Action
  include Rails.application.routes.url_helpers
  include ActionView::Helpers

  def type_abbr
    'Hint'
  end

  def as_text
    'Provide a hint for message matching'
  end

  def description
    'Provides a matching hint to help the system match responses'
  end

  def execute(opts={})
    true
  end
end
