# repositories/load_history_repository.rb
class LoadHistoryRepository
  def initialize
    @storage = Hash.new { |h, k| h[k] = [] }
  end

  def history_for(customer_id)
    storage[customer_id]
  end

  def save(fund_load_attempt, effective_amount)
    storage[fund_load_attempt.customer_id] << {
      id: fund_load_attempt.id,
      date: fund_load_attempt.date,
      effective_amount: effective_amount
    }
  end

  private

  attr_reader :storage
end
