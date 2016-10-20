require 'spec_helper'

describe DatePickerInput do
  it "#input " do
    expect(DatePickerInput.new(double.as_null_object,
      double,double,
      double).input).not_to be_nil
  end
end