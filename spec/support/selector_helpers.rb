module SelectorHelpers

  def navigation_selector
    'nav#top-menu'
  end

  def page_selector
    '#page'
  end

  def container_selector
    '.container'
  end

  def page_header_selector
    '.page-header'
  end

  def div_id_selector(id_name)
    [:xpath, "//div[@id='#{id_name}']"]
  end

  def div_class_selector(id_name)
    [:xpath, "//div[@class='#{id_name}']"]
  end

  def a_id_selector(id_name)
    [:xpath, "//a[@id='#{id_name}']"]
  end

  def a_class_selector(id_name)
    [:xpath, "//a[@class='#{id_name}']"]
  end

  def h1_id_selector(id_name)
    [:xpath, "//h1[@id='#{id_name}']"]
  end

  def h1_class_selector(id_name)
    [:xpath, "//h1[@class='#{id_name}']"]
  end

  def select_id_selector(id_name)
    [:xpath, "//select[@id='#{id_name}']"]
  end

  def select_class_selector(id_name)
    [:xpath, "//select[@class='#{id_name}']"]
  end

end
