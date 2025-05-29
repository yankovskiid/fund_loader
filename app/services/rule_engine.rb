class RuleEngine
  def initialize(strategies)
    @strategies = strategies
  end

  def evaluate(fund_load_attempt, context)
    strategies.all? { |strategy| strategy.call(fund_load_attempt, context) }
  end

  private

  attr_reader :strategies
end
