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
      @subscriber = create(params[:search],user:@user)
      @channel.subscribers << @subscriber
      within navigation_selector do
        click_link 'Subscribers'
      end
      within page_selector do
        click_link @subscriber.name
      end
    end
    scenario 'has the list searched subscribers' do
      within page_header_selector do
        expect(page).to have_content(@subscriber.name)
      end
    end
  end
end
