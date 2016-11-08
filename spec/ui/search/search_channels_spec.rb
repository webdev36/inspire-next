require 'spec_helper'

  feature 'UI/Users', js: true do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end
  context '#index' do
    background do
      @ordered_channel = create(:ordered_messages_channel, user:@user)
      @on_demand_channel = create(:on_demand_messages_channel, user:@user)
      @annoucements_channel = create(:announcements_channel, user:@user)
      @channels = [@ordered_channel,@on_demand_channel,@annoucements_channel]
      within navigation_selector do
        click_link 'Channels'
      end
    end
    scenario "user searches channel about name" do
    	fill_in "search", :with => 'Test'
    	keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
			page.driver.execute_script(keypress)
			
			expect(page).to have_text("Channels and Channel Groups") 
    end
  end
end