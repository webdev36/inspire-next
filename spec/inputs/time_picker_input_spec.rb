require 'spec_helper'

describe TimePickerInput do
  it "#input " do
    TimePickerInput.new(double.as_null_object,
      double.as_null_object,double.as_null_object,
      double.as_null_object).input.should_not be_nil
  end
end