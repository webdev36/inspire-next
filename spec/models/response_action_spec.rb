require 'spec_helper'

describe ResponseAction do
  its "factory works" do
    expect(build(:response_action)).to be_valid
  end

  it "requires response_text" do
    expect(build(:response_action,response_text:'')).to_not be_valid
  end
  
end
