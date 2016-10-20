require 'spec_helper'

feature 'Channel Groups' do
  background do
    @user = create(:user)
    sign_in_using_form(@user)
    @cg1 = create(:channel_group, user:@user)
    @cg2 = create(:channel_group, user:@user)
    @channel_groups = [@cg1,@cg2]     
  end

  context 'list is shown on user\'s landing page.' do
    background do
      within "div#top-menu" do
        click_link 'Live Inspired'
      end 
    end
    scenario 'It shows all channel groups created by the user' do
      within 'div#channel-groups-section' do
        @channel_groups.each do |channel_group|
          expect(page).to have_content(channel_group.name)
        end
      end
    end
    scenario 'New channel group can be created from here' do
      within 'div#channel-groups-section' do
        click_link 'New'
      end
      expect(page).to have_title('New Channel Group')
    end    
  end
  context 'list is shown on channels index page.' do
    background do
      within "div#top-menu" do
        click_link 'Channels'
      end 
    end
    scenario 'It shows all channel groups created by the user' do
      within 'div#channel-groups-section' do
        @channel_groups.each do |channel_group|
          expect(page).to have_content(channel_group.name)
        end
      end
    end
    scenario 'New channel group can be created from here' do
      within 'div#channel-groups-section' do
        click_link 'New'
      end
      expect(page).to have_title('New Channel Group')
    end
  end  
  context "edit page" do
    background do
      @ch1 = create(:channel,user:@user)
      @ch2 = create(:channel,user:@user)
      @cg1.channels << @ch1
      @cg1.channels << @ch2
      within "div#top-menu" do
        click_link 'Live Inspired'
      end 
      within "div#channel-groups-section tr#channel_group_#{@cg1.id}" do
        click_link 'Edit'
      end      
    end
    scenario "shows the default channel field" do
      page.should have_select('channel_group_default_channel_id')
    end
  end
  context "show page" do
    background do
      @ch1 = create(:channel,user:@user)
      @ch2 = create(:channel,user:@user)
      @cg1.channels << @ch1
      @cg1.default_channel = @ch1
      @cg1.save
      within "div#top-menu" do
        click_link 'Live Inspired'
      end 
      within 'div#channel-groups-section' do
        click_link @cg1.name
      end
    end
    scenario "shows the channels belonging to this group" do
      within "div#channel-list" do
        expect(page).to have_content(@ch1.name)
      end
    end
    scenario "shows the default channel of this group" do
      within "dl#channel-group-details" do
        expect(page).to have_content(@ch1.name)
      end
    end

    scenario "allows addition of a channel to the group" do
      within "div#channel-list" do
        click_link 'Add'
      end      
      expect(page).to have_title("New Channel")
      within "form#new_channel" do
        page.should have_select('channel_channel_group_id',:selected=>@cg1.name)
        @new_channel_name = Faker::Lorem.word
        fill_in 'channel_name', with: @new_channel_name
        click_button 'Create Channel'
      end
      click_link 'Back'
      within 'div#channel-groups-section' do
        click_link @cg1.name
      end
      within "div#channel-list" do
        expect(page).to have_content(@new_channel_name)
      end
    end
  end
end