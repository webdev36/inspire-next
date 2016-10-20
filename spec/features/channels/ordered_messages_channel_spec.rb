require 'spec_helper'

feature 'Ordered Messages Channel', :js=>true do
  background do
    @user = create(:user)
    sign_in_using_form(@user)  
  end
  context "creation" do
    background do
      within "div#top-menu" do
        click_link 'Channels'
      end
      within "div#channels-section" do
        click_link 'New'
      end      
      select 'Ordered messages channel', from:'channel_type'            
    end
    scenario "is possible from the new form" do
      name = Faker::Lorem.words(2).join(' ')
      fill_in "Name", with:name
      fill_in "channel_tparty_keyword", with:'+14084084080'
      click_button "Create Channel"
      expect(page).to have_title(name.titleize)
    end
    scenario "allows schedule to be set" do
      expect(page).to have_css("select#channel_schedule")
    end    
    
  end  
  context "show" do
    background do
      @channel = create(:ordered_messages_channel, user:@user)
      @messages = (0..2).map{create(:message, channel:@channel)}
      within "div#top-menu" do
        click_link 'Channels'
      end         
      within "div#channels-section" do
        click_link @channel.name
      end
    end
      
    scenario "does not have button to trigger message broadcast" do
      expect(page).to_not have_link('Broadcast')
    end  

    
    scenario "it lists the up and down button alongside messages" do
      @messages.each do |message|
        within("div#message-list tr#message_#{message.id}") do
          expect(page).to have_link('Up')
          expect(page).to have_link('Down')
        end
      end
    end
    
    scenario "the default sort order of messages is chronological" do
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[1]).to have_content(@messages[0].title)
        expect(rows[2]).to have_content(@messages[1].title)
        expect(rows[3]).to have_content(@messages[2].title)
      end
    end  

    scenario "it is possible to move the messages up and down" do
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[1]).to have_content(@messages[0].title)
        expect(rows[2]).to have_content(@messages[1].title)
        expect(rows[3]).to have_content(@messages[2].title)
        rows[3].click_link('Up')        
      end
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[2]).to have_content(@messages[2].title)
        rows[2].click_link('Up')
      end
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[1]).to have_content(@messages[2].title)
        expect(rows[2]).to have_content(@messages[0].title)
        expect(rows[3]).to have_content(@messages[1].title)
        rows[1].click_link('Down')
      end
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[2]).to have_content(@messages[2].title)
        rows[2].click_link('Down')
      end
      within_table 'messages_table' do
        rows = all('tr')
        expect(rows[1]).to have_content(@messages[0].title)
        expect(rows[2]).to have_content(@messages[1].title)
        expect(rows[3]).to have_content(@messages[2].title)
      end
    end      
  end
end