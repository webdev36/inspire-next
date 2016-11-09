require 'spec_helper'

feature 'UI/User', js: true do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end
  
  scenario 'user searches channel about name' do
    within '#channels-section' do
      fill_in "search", with: "test"
    	keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
			page.driver.execute_script(keypress)
    end
    visit channels_path
    expect(page).to have_text("Channels and Channel Groups")
  end 

  scenario 'user searches subscriber about name' do
      within '#subscribers-section' do
        fill_in 'search', :with => "ethan"
        keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
        page.driver.execute_script(keypress)
      end
      visit subscribers_path
      expect(page).to have_text("Subscribers")
    end

    scenario 'user searches subscriber about number' do
      within '#subscribers-section' do
        fill_in 'search', :with => "+11111111111"
        keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
        page.driver.execute_script(keypress)
      end
      visit subscribers_path
      expect(page).to have_text("Subscribers")
    end
    
end

