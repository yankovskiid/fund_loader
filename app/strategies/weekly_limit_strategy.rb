class WeeklyLimitStrategy
  def initialize(config)
    @weekly_limit = config['fund_load_limits']['weekly_limit']
  end

  def call(fund_load_attempt, context)
    effective_amount = context[:effective_amount]
    week_range = context[:week_range]

    weekly_total = context[:history]
                     .select { |attempt| week_range.cover?(attempt[:date]) }
                     .sum { |attempt| attempt[:effective_amount] }

    (weekly_total + effective_amount) <= weekly_limit
  end

  private

  attr_reader :weekly_limit
end
