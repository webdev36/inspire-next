class RuleWorker
  include Sidekiq::Worker

  def perform(id)
    StatsD.increment("rule_worker.#{id}.run")
    rule = Rule.find(id)
    rule.run
    rule.next_run_at = Time.now + 1.hour
    rule.save
  end
end
