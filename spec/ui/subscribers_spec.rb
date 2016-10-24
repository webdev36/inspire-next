require 'spec_helper'

feature 'UI/Subscribers' do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end

  context 'in its show/details page' do
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
    scenario 'has the subscriber name as header' do
      within page_header_selector do
        expect(page).to have_content(@subscriber.name)
      end
    end
    scenario 'has the subscriber phone number' do
      expect(page).to have_content(@subscriber.phone_number)
    end
    scenario 'has a button that leads to the list of subscriber activities' do
      click_link 'Subscriber Activities'
      within page_header_selector do
        expect(page).to have_content("Subscriber activities of #{@subscriber.name}")
      end
    end
  end
end
