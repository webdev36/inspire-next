require 'spec_helper'

feature 'UI/User', js: true do
  background do
    @user = create(:user)
    @channel = create(:channel, user:@user)
    @channel_group = create(:channel_group, user:@user)
    @channel_2 = create(:channel, channel_group:@channel_group)
    @message = create(:message, channel:@channel)
    @subscriber = create(:subscriber,user:@user)
    @channel.subscribers << @subscriber
    sign_in_using_form(@user)
  end

  context 'in user show page' do
    scenario 'has the subscriber email in header' do
      visit(user_path(@user))
      within page_header_selector do
        expect(page).to have_content(@user.email)
      end
    end

    scenario 'user searches channel about name' do
      within '#channels-section' do
        fill_in 'search', :with => "test"
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
  end
end
