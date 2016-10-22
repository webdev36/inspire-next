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
      @channels = [@ordered_channel,@on_demand_channel,@annoucements_channel]
      within navigation_selector do
        click_link 'Channels'
      end
    end
    scenario "should list all the channels" do
      within *div_id_selector('channels-section') do
        @channels.each do |channel|
          expect(page).to have_content(channel.name)
        end
      end
    end
  end

  context '#new' do
    background do
      within navigation_selector do
        click_link 'Channels'
      end
      within *div_id_selector('channels-section') do
        find(*a_id_selector('channel-new')).click
      end
    end

    scenario 'it is possible to select the type of channel' do
      expect(page).to have_css "select#channel_type"
      expect(page).not_to have_css "select#channel_type.readonly"
    end

    scenario "displays the keyword and tparty_keyword fields" do
      expect(page).to have_css("input#channel_keyword")
      expect(page).to have_css("input#channel_tparty_keyword")
    end

    scenario "shows/hides scheduling controls based on channel type" do
      select 'OrderedMessagesChannel', from:'channel_type'
      expect(page).to have_css("select#channel_schedule")
      select 'OnDemandMessagesChannel', from:'channel_type'
      expect(page).not_to have_css("select#channel_schedule")
    end
  end

  context 'in the edit page' do
    background do
      @channel = create(:ordered_messages_channel, user:@user)
      within navigation_selector do
        click_link 'Channels'
      end
      within "tr#channel_#{@channel.id}" do
        click_link 'Edit'
      end
    end
    scenario 'it is not possible to change channel type' do
      # make sure it has a readonly attribute
      within page_selector do
        expect(find("select#channel_type").readonly?).to be_truthy
      end
    end
  end

  context '#show' do
    background do
      @channel     = create(:ordered_messages_channel, user:@user)
      @messages    = (0..2).map{ create(:message, channel:@channel) }
      @subscribers = (0..2).map{ create(:subscriber,user:@user) }
      @subscribers.each do |subs|
        @channel.subscribers << subs
      end
      within navigation_selector do
        click_link 'Channels'
      end
      within page_selector do
        click_link @channel.name
      end
    end
    scenario "has the name as header" do
      within "#page-header" do
        expect(page).to have_content(@channel.name)
      end
    end

    scenario "lists its subscribers" do
      @subscribers.each do |subscriber|
        expect(page).to have_content(subscriber.name)
      end
    end

    scenario "lists its messages" do
      tr_ids = all("tr").map {|x| x['id'] }
      @messages.each do |message|
        expect(tr_ids.include?("message_#{message.id}")).to be_truthy
      end
    end
  end

  context 'where broadcast is important' do
    background do
      @annoucements_channel = create(:announcements_channel, user:@user)
      @announcement_messages = (0..2).map{create(:message, channel:@annoucements_channel)}
      within navigation_selector do
        click_link 'Channels'
      end
    end
    context 'in its details page' do
      background do
        within "div#channels-section" do
          click_link @annoucements_channel.name
        end
      end
      scenario "has button to trigger message broadcast" do
        within("div#message-list tr#message_#{@announcement_messages[1].id}") do
          expect(page).to have_link('Broadcast')
        end
      end
    end
  end

  context "where sequence is important" do
    background do
      @channel = create(:ordered_messages_channel, user:@user)
      @messages = (0..2).map{create(:message, channel:@channel)}
      within navigation_selector do
        click_link 'Channels'
      end
    end
    context "in the details page" do
      background do
        within "div#channels-section" do
          click_link @channel.name
        end
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
          expect( rows[1]['id'].gsub("message_", '').to_i == @messages[0].id ).to be_truthy
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[1].id ).to be_truthy
          expect( rows[3]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
        end
      end

      scenario "it is possible to move the messages up and down" do
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[1]['id'].gsub("message_", '').to_i == @messages[0].id ).to be_truthy
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[1].id ).to be_truthy
          expect( rows[3]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
          rows[3].click_link('Up')
        end
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
          rows[2].click_link('Up')
        end
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[1]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[0].id ).to be_truthy
          expect( rows[3]['id'].gsub("message_", '').to_i == @messages[1].id ).to be_truthy
          rows[1].click_link('Down')
        end
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
          rows[2].click_link('Down')
        end
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[1]['id'].gsub("message_", '').to_i == @messages[0].id ).to be_truthy
          expect( rows[2]['id'].gsub("message_", '').to_i == @messages[1].id ).to be_truthy
          expect( rows[3]['id'].gsub("message_", '').to_i == @messages[2].id ).to be_truthy
        end
      end
    end
  end

  context "where sequence is not important" do
    background do
      @random_channel = create(:random_messages_channel, user:@user)
      @random_messages = (0..2).map{create(:message,channel:@random_channel)}
      within navigation_selector do
        click_link 'Channels'
      end
    end
    context "in the details page" do
      background do
        within "div#channels-section" do
          click_link @random_channel.name
        end
      end

      scenario "it does not list the up and down button alongside messages" do
        @random_messages.each do |message|
          within("div#message-list tr#message_#{message.id}") do
            expect(page).to_not have_link('Up')
            expect(page).to_not have_link('Down')
          end
        end
      end

      scenario "the default sort order of messages is reverse chronological" do
        within_table 'messages_table' do
          rows = all('tr')
          expect( rows[1]['id'].gsub("message_", '').to_i == @random_messages[2].id ).to be_truthy
          expect( rows[2]['id'].gsub("message_", '').to_i == @random_messages[1].id ).to be_truthy
          expect( rows[3]['id'].gsub("message_", '').to_i == @random_messages[0].id ).to be_truthy
        end
      end
    end
  end

  context "where scheduling is important" do
    background do
      @ordered_channel = create(:ordered_messages_channel, user:@user)
      within navigation_selector do
        click_link 'Channels'
      end
    end
    context "in the edit page" do
      background do
        within "tr#channel_#{@ordered_channel.id}" do
          click_link 'Edit'
        end
      end
      scenario "displays scheduling controls" do
        expect(page).to have_css("select#channel_schedule")
      end
    end
  end

  context "where scheduling is not relevant" do
    background do
      @on_demand_channel = create(:on_demand_messages_channel, user:@user)
      within navigation_selector do
        click_link 'Channels'
      end
    end
    context "in the edit page" do
      background do
        within "tr#channel_#{@on_demand_channel.id}" do
          click_link 'Edit'
        end
      end
      scenario "does not display scheduling controls" do
        expect(page).not_to have_css("select#schedule")
      end
    end
  end

end
