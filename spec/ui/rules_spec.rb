require 'spec_helper'

feature 'UI/Rules' do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end

  context 'in its index page' do
    background do
      @channel = create(:channel, user: @user)
      @message = create(:message, channel: @channel)
      @subscriber = create(:subscriber,user: @user)
      @channel.subscribers << @subscriber
      within navigation_selector do
        click_link 'Rules'
      end
    end
    scenario 'has the name Rules' do
      within page_header_selector do
        expect(page).to have_content('Rules')
      end
      expect(page).to have_selector(:link_or_button, 'New Rule')
    end
  end
end
