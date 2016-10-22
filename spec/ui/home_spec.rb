require 'spec_helper'

feature 'UI/home page' do
  scenario 'has welcome text' do
    visit root_path
    expect(page).to have_content('Give it a spin')
  end

  scenario 'has signin and signup buttons for non-logged in users' do
    visit root_path
    within "div#page" do
      expect(page).to have_link('Sign up')
      expect(page).to have_link('Sign in')
    end
  end

  scenario 'has signout and edit profile button for logged in users' do
    user = create(:user)
    visit root_path
    sign_in_using_form(user)
    visit root_path
    expect(page).to have_link('Sign out')
    expect(page).to have_link('Edit Profile')
  end
end
