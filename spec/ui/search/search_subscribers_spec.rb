require 'spec_helper'

  feature 'UI/Users', js: true do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end
  context '#index' do
    background do
      @channel = create(:channel, user:@user)
      @message = create(:message, channel:@channel)
      @subscriber = create(:subscriber,user:@user)
      @channel.subscribers << @subscriber
      within navigation_selector do
        click_link 'Subscribers'
      end
      within page_selector do
        click_link @subscriber.name
      end
    end
    scenario "user searches subscriber about name" do
    	fill_in "search", :with => 'Ethan'
    	keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
			page.driver.execute_script(keypress)
			
			expect(page).to have_content("Subscribers") 
    end
    
    scenario "user searches subscriber about number" do
    	fill_in "search", :with => '+11111111111'
    	keypress = "var e = $.Event('keydown', { keyCode: 13 }); $('body').trigger(e);"
			page.driver.execute_script(keypress)
			
			expect(page).to have_content("Subscribers") 
    end
  end
end