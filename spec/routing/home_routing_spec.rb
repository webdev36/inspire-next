require 'spec_helper'

describe 'root' do
  it 'routes to home controller' do
    expect(:get=>'/').to route_to(
      :controller => 'home',
      :action => 'index')
  end
end