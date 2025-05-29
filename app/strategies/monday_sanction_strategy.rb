require_relative './daily_limit_strategy'
require_relative './weekly_limit_strategy'

class MondaySanctionStrategy
  def initialize(config)
    @monday_multiplier = config['special_sanctions']['monday_multiplier']
    @daily_limit_strategy = DailyLimitStrategy.new(config)
    @weekly_limit_strategy = WeeklyLimitStrategy.new(config)
  end

  def call(fund_load_attempt, context)
    date = fund_load_attempt.date
    amount = fund_load_attempt.amount

    context[:effective_amount] = date.monday? ? amount * monday_multiplier : amount

    return false unless daily_limit_strategy.call(fund_load_attempt, context)
    return false unless weekly_limit_strategy.call(fund_load_attempt, context)

    true
  end

  private

  attr_reader :monday_multiplier, :daily_limit_strategy, :weekly_limit_strategy
end
