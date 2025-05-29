class DailyCountStrategy
  def initialize(config)
    @daily_count_limit = config['fund_load_limits']['daily_load_count_limit']
  end

  def call(fund_load_attempt, context)
    date = fund_load_attempt.date

    daily_attempt_count = context[:history].count { |attempt| attempt[:date] == date }

    daily_attempt_count < daily_count_limit
  end

  private

  attr_reader :daily_count_limit
end
