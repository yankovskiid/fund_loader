require_relative '../utils/prime_utils'

class PrimeSanctionStrategy
  def initialize(config)
    @prime_config = config['special_sanctions']['prime_id']
  end

  def call(fund_load_attempt, context)
    id = fund_load_attempt.id.to_i
    date = context[:date]
    amount = context[:amount]

    return true unless PrimeUtils.prime?(id)
    return false if context[:prime_ids].include?(date)
    return false if amount > prime_config['max_amount']

    context[:prime_ids] << date
    true
  end

  private

  attr_reader :prime_config
end
