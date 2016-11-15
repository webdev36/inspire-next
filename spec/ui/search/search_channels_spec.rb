require 'spec_helper'

feature 'UI/Channels', js: true do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
  end

  context '#index' do
    background do
      @ordered_channel = create(:ordered_messages_channel, user:@user)
      @on_demand_channel = create(:on_demand_messages_channel, user:@user)
      @annoucements_channel = create(:announcements_channel, user:@user)
      @search_channel = create(:channel, user:@user, name: 'abc123 channel')
      @channels = [@search_channel]
      within navigation_selector do
        click_link 'Channels'
      end
    end
    scenario "should list all the searched channels" do
      within *div_id_selector('channels-section') do
        @channels.each do |channel|
          expect(page).to have_content(channel.name)
        end
      end
    end
    scenario "should list all the searched channels" do
      within *div_id_selector('channels-section') do
        @channels.each do |channel|
          expect(page).to have_content(channel.name)
        end
      end
    end
  end
end
