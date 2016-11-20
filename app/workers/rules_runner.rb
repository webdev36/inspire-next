class RulesRunner
  include Sidekiq::Worker

  def perform
    StatsD.increment("rules_runner.run")
    Rule.active.due.each do |rule|
      RuleWorker.enqueue(rule.id)
    end
  end
end
