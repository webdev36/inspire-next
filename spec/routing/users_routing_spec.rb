require "spec_helper"

describe UsersController do
  describe "routing" do

    it "routes to #show" do
      get("users/2").should route_to controller:'users',action:'show',:id=>'2'
    end
  end
end