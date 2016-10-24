# == Schema Information
#
# Table name: actions
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  as_text         :text
#  deleted_at      :datetime
#  actionable_id   :integer
#  actionable_type :string(255)
#

require 'spec_helper'

describe Action do
  it "factory works" do
    expect(build(:action)).to be_valid
  end

  it "requires a type" do
    expect(build(:action,type:"")).to_not be_valid
  end

  it "sets the model_name of any subclass as Action to enable STI use single controller" do
    expect(SwitchChannelAction.model_name).to eq(Action.model_name)
  end    

  it "requires type to be one of identified actions" do
    expect(build(:action,type:"SwitchChannelAction")).to be_valid
    expect(build(:action,type:'SendMessageAction')).to be_valid
    expect(build(:action,type:"UnknownAction")).to_not be_valid
  end

  # it "requires as_text to not be blank" do
  #   expect(build(:action,as_text:"")).to_not be_valid
  # end

  it "subclasses override all abstract methods" do
    Dir[Rails.root.join("app","models","actions","*.rb")].each {|f| require f}
    Action.child_classes.each do |sub_class|
       cmd = create(sub_class.to_s.underscore.to_sym)
      expect{cmd.type_abbr}.to_not raise_error
      expect{cmd.execute}.to_not raise_error
      expect{cmd.description}.to_not raise_error
    end
  end




end
