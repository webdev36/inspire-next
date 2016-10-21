module LoginMacros
  def sign_in_using_form(user)
    visit root_path
    find('nav#top-menu').click_link('Sign in')
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    Array(find('input[type="submit"]')).first.click
  end

  def navigation_selector
    'nav#top-menu'
  end

  def page_selector
    'nav#top-menu'
  end

  def container_selector
    '.container'
  end

  def write_for_inspection(page = nil)
    return false unless page && page.is_a?(Capybara::Session)
    hex = SecureRandom.hex(4)
    write_screenshot_to_tmp_path(page, hex)
    write_tmp_page_for_inspection(page, hex)
  end

  def write_tmp_page_for_inspection(page, hex = nil)
    hex = SecureRandom.hex(4) unless hex
    Files.write_to_tmp_path("doc-#{hex}.html", page.html)
  end

  def write_screenshot_to_tmp_path(page, hex = nil)
    hex = SecureRandom.hex(4) unless hex
    # page.save_screenshot("#{Files.tmp_path}#{hex}.png")
  end
end
