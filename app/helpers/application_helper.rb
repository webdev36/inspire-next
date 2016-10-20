module ApplicationHelper
  def will_paginate(collection_or_options = nil, options={})
    if collection_or_options.is_a? Hash
      options,collection_or_options = collection_or_options,nil
    end
    unless options[:renderer]
      options = options.merge :renderer => BootstrapPagination::Rails
    end
    super *[collection_or_options, options].compact
  end

  def print_or_dashes(text)
    text.blank? ? '---' : text
  end

  def action_types 
    Action.child_classes.map {|klass| klass.to_s.to_sym}
  end
end
