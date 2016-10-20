require 'spec_helper'

feature 'navigation menu' do
  scenario 'has signin link for non-logged in users' do
    visit root_path
    within "div#top-menu" do
      expect(page).to have_link('Sign in')
      expect(page).to_not have_link('Sign out')
    end
  end  

  context 'for logged in users' do
    background do
      visit root_path
      user = create(:user)
      sign_in_using_form(user)    
    end
    
    scenario 'has signout link' do
      within "div#top-menu" do
        expect(page).to have_link('Sign out')
        expect(page).to_not have_link('Sign in')
      end
    end  
    
    scenario 'has channels link' do
      within "div#top-menu" do
        expect(page).to have_link('Channels')
      end      
    end

    scenario 'has profile link' do
      within "div#top-menu" do
        expect(page).to have_link("Profile")
      end
    end
  end


end