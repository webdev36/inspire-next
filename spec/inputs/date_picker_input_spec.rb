require 'spec_helper'

describe DatePickerInput do
  it "#input " do
    DatePickerInput.new(double.as_null_object,
      double,double,
      double).input.should_not be_nil
  end
end