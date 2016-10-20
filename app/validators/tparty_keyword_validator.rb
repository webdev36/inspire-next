class TpartyKeywordValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    error = MessagingManager.new_instance.validate_tparty_keyword(value)
    if error
      record.errors[attribute] << (options[:message] || error)
    end
  end
end