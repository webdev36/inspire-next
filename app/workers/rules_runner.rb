class RulesRunner
  include Sidekiq::Worker

  def perform
    Rails.logger.info "class=rules_runner action=start"
    StatsD.increment("rules_runner.run")
    Rule.active.due.each do |rule|
      RuleWorker.enqueue(rule.id)
    end
  end
end
