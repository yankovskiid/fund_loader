class DailyLimitStrategy
  def initialize(config)
    @daily_limit = config['fund_load_limits']['daily_limit']
  end

  def call(fund_load_attempt, context)
    date = fund_load_attempt.date
    effective_amount = context[:effective_amount]

    daily_total = context[:history]
                    .select { |attempt| attempt[:date] == date }
                    .sum { |attempt| attempt[:effective_amount] }

    (daily_total + effective_amount) <= daily_limit
  end

  private

  attr_reader :daily_limit
end
