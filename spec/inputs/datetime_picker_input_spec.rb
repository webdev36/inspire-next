require 'spec_helper'

describe DatetimePickerInput do
  it "#input " do
    DatetimePickerInput.new(double.as_null_object,
      double.as_null_object,double.as_null_object,
      double.as_null_object).input.should_not be_nil
  end
end