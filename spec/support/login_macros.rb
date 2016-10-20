module LoginMacros
  def sign_in_using_form(user)
    visit root_path
    within 'div#top-menu' do
      click_link 'Sign in'
    end
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign in'
  end
end