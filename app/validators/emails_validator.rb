class EmailsValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    emails = value.split.join(',')
    emails = emails.split(/[,;]/)
    emails.reject!(&:blank?)
    format = :fine
    emails.each do |email|
      unless email=~/^.+@.+$/
        format = :error
      end
    end
    if format==:error
      record.errors[attribute] << (options[:message] || 'format is not valid')
    end
  end
end