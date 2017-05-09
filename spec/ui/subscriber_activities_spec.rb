require 'spec_helper'

feature 'UI/Subscriber Activities' do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end

  context 'shows subscriber activity details' do
    background do
      @channel = create(:channel, user:@user)
      @message = create(:message, channel:@channel)
      @subscriber = create(:subscriber,user:@user)
      @subscriber_activity = create(:subscriber_activity, subscriber:@subscriber)
      @channel.subscribers << @subscriber
      within navigation_selector do
        click_link 'Subscribers'
      end
      within page_selector do
        click_link @subscriber.name
      end
      within page_selector do
        click_link 'Subscriber Activities'
      end
      within page_header_selector do
        expect(page).to have_content("Subscriber activities of #{@subscriber.name}")
      end
    end
  end
end
