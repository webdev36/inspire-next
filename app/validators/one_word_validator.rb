class OneWordValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    if value.blank?
      record.errors[attribute] << (options[:message] || 'is not one word long')
    else
      words = value.split
      record.errors[attribute] << (options[:message] || 'is not one word long') if words.length != 1
    end
  end
end