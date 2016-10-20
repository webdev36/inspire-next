require 'spec_helper'

feature 'Subscribers' do
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
      within "div#top-menu" do
        click_link 'Subscribers'
      end         
      within "div#page" do
        click_link @subscriber.name
      end
    end
    scenario 'has the subscriber name as header' do
      within "h1" do
        expect(page).to have_content(@subscriber.name)
      end
    end
    scenario 'has the subscriber phone number' do
      page.should have_content(@subscriber.phone_number)
    end
    scenario 'has a button that leads to the list of subscriber activities' do
      click_link 'Subscriber Activities'
      within 'h1' do 
        expect(page).to have_content("Subscriber activities of #{@subscriber.name}")
      end
    end
  end  
end