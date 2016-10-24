require 'spec_helper'

describe ResponseAction do
  describe '#factory works' do
    subject { super().factory works }
    it do
    expect(build(:response_action)).to be_valid
  end
  end

  it "requires response_text" do
    expect(build(:response_action,response_text:'')).to_not be_valid
  end
  
end
