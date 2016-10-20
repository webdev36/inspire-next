require 'spec_helper'

describe DatetimePickerInput do
  it "#input " do
    expect(DatetimePickerInput.new(double.as_null_object,
      double.as_null_object,double.as_null_object,
      double.as_null_object).input).not_to be_nil
  end
end