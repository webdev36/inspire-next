module ResponsiveHelpers

  def resize_window_to_mobile
    resize_window_to(640, 480)
  end

  def resize_window_to_tablet
    resize_window_to(960, 640)
  end

  def resize_window_default
    resize_window_to(1024, 768)
  end

  private

  def resize_window_to(width, height)
    Capybara.current_session.driver.browser.manage.window.resize_to(width, height) if Capybara.current_session.driver.browser.respond_to? 'manage'
  end

end
