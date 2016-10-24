require 'spec_helper'
require 'support/integration_setups.rb'

describe 'Integration/JordanOldIHelpCase' do

  let(:file_path) { "#{Files.fixture_path}/integration/user_cases/jordan_old_ihelp/5_sql_export_1477275267.sql" }
  let(:run_iterations) { 20 } # 480 is 24 hours * 60 minutes/hour / 3 minutes per iteration

  xit 'behaves' do
    importer = ImportSqlUserData.new(file_path)
    resp = importer.sql_import
    expect(resp[:errors].length == 0).to be_truthy
    now = Time.now
    frozen_time = Time.now.freeze
    travel_to_time(now)
    counter = 0
    before_stats
    until counter == run_iterations
      puts "\n\n****\n* Its #{Time.now}\n******"
      last_time = Time.now
      run_worker!
      travel_to_time(last_time + 3.minutes)
      counter += 1
    end
    after_stats
    binding.pry
  end

  def before_stats
    @before_stats ||= begin
      bs = {}
      bs = subscriber_stats(bs)
      bs
    end
  end

  def after_stats
    @after_stats ||= begin
      as = {}
      as = subscriber_stats(as)
      as
    end
  end

  def subscriber_stats(store_hash)
    Subscriber.all.each do |subscriber|
      store_hash[subscriber.id] = {} if store_hash[subscriber.id].blank?
      store_hash[subscriber.id] = subscriber.delivery_notices.count
      store_hash[subscriber.id] = subscriber.delivery_error_notices.count
    end
    store_hash
  end

end
