require 'spec_helper'

feature 'UI/Subscriber' do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end

  context 'in its show/details page' do
    background do
      @channel = create(:channel, user:@user)
      @message = create(:message, channel:@channel)
      @search_subscriber = create(:subscriber,user:@user, name: 'Apple Orange')
      @other_subscriber = create(:subscriber, user:@user, name: 'Banana Coconut')
      @channel.subscribers << @search_subscriber
      @channel.subscribers << @other_subscriber
      within navigation_selector do
        click_link 'Subscribers'
      end
    end
    scenario 'can search and find subscribers by' do
      fill_in 'subscribers_search', :with => 'apple'
      click_button('Search')
      page.all('table#subscribers_table tr').count.should == 1
      page.should have_content('Apple')
      page.should_not have_content('Banana')
    end
  end
end
