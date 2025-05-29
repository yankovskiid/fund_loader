require 'set'

class FundLoadProcessor
  def initialize(rule_engine:, repository:)
    @rule_engine = rule_engine
    @repository = repository
    @prime_ids = Set.new
  end

  def process(fund_load_attempt)
    context = build_context(fund_load_attempt)

    accepted = rule_engine.evaluate(fund_load_attempt, context)

    repository.save(fund_load_attempt, context[:effective_amount]) if accepted

    {
      id: fund_load_attempt.id,
      customer_id: fund_load_attempt.customer_id,
      accepted: accepted
    }
  end

  private

  attr_reader :rule_engine, :repository, :prime_ids

  def build_context(fund_load_attempt)
    date = fund_load_attempt.date
    {
      date: date,
      amount: fund_load_attempt.amount,
      effective_amount: fund_load_attempt.amount,
      history: repository.history_for(fund_load_attempt.customer_id),
      week_range: (date - date.wday)..(date + (6 - date.wday)),
      prime_ids: prime_ids
    }
  end
end
