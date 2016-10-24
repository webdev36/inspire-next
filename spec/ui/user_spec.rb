require 'spec_helper'

feature 'UI/User' do
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
  end
end
