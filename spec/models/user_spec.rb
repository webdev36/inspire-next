# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  admin                  :boolean          default(FALSE)
#

require 'spec_helper'

describe User do
  it "has a working factory" do
    expect(build(:user)).to be_valid
  end
  it "requires a email" do
    expect(build(:user,email:'')).to_not be_valid
  end
  it "requires an unique email" do
    user = create(:user)
    expect(build(:user,email:user.email)).to_not be_valid
  end
end
