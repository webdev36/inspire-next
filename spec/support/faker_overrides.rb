module Faker
  class PhoneNumber
    class << self
      def us_phone_number
        "(#{rand(100..999)}) #{rand(100..999)} #{rand(1000..9999)}"
      end
    end
  end
end