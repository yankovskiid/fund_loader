require 'rspec'
require 'date'
require_relative '../../app/strategies/weekly_limit_strategy'
require_relative '../../app/models/fund_load_attempt'
require_relative '../../app/repositories/load_history_repository'

RSpec.describe WeeklyLimitStrategy do
  let(:config) { { 'fund_load_limits' => { 'weekly_limit' => 20_000.0 } } }
  let(:repository) { LoadHistoryRepository.new }
  subject(:strategy) { WeeklyLimitStrategy.new(config) }

  before do
    repository.save(FundLoadAttempt.new({ "id" => "1", "customer_id" => "123", "load_amount" => "$10000", "time" => "2025-05-26T10:00:00Z" }), 10_000.0)
    repository.save(FundLoadAttempt.new({ "id" => "2", "customer_id" => "123", "load_amount" => "$5000", "time" => "2025-05-28T12:00:00Z" }), 5000.0)
  end

  describe '#call' do
    context 'when the weekly total is below the limit' do
      let(:context) do
        {
          week_range: Date.new(2025, 5, 25)..Date.new(2025, 5, 31),
          history: repository.history_for("123"),
          effective_amount: 3000.0
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$3000", "time" => "2025-05-29T14:00:00Z" }) }

      it 'allows the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(true)
      end
    end

    context 'when the weekly total exceeds the limit' do
      before do
        repository.save(FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$9000", "time" => "2025-05-29T14:00:00Z" }), 9000.0)
      end

      let(:context) do
        {
          week_range: Date.new(2025, 5, 25)..Date.new(2025, 5, 31),
          history: repository.history_for("123"),
          effective_amount: 3000.0
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "4", "customer_id" => "123", "load_amount" => "$3000", "time" => "2025-05-30T14:00:00Z" }) }

      it 'rejects the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(false)
      end
    end

    context 'when the transaction amount is zero' do
      let(:context) do
        {
          week_range: Date.new(2025, 5, 25)..Date.new(2025, 5, 31),
          history: repository.history_for("123"),
          effective_amount: 0.0
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$0", "time" => "2025-05-29T14:00:00Z" }) }

      it 'allows the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(true)
      end
    end
  end
end