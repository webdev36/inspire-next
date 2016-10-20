require 'spec_helper'

feature 'signin' do
  scenario 'after success redirects to user show page' do
    user = create(:user)
    sign_in_using_form(user)
    within 'h2#user_email' do
      expect(page).to have_content(user.email)
    end
  end
end