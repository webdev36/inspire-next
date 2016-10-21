require 'spec_helper'

feature 'UI/Sign in' do
  scenario 'after success redirects to user show page' do
    user = create(:user)
    sign_in_using_form(user)
    expect(page).to have_content(user.email)
  end
end
