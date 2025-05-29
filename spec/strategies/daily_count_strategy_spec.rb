require 'rspec'
require 'date'
require_relative '../../app/strategies/daily_count_strategy'
require_relative '../../app/models/fund_load_attempt'
require_relative '../../app/repositories/load_history_repository'

RSpec.describe DailyCountStrategy do
  subject(:strategy) { DailyCountStrategy.new(config) }
  let(:config) { { 'fund_load_limits' => { 'daily_load_count_limit' => 3 } } }
  let(:repository) { LoadHistoryRepository.new }

  before do
    repository.save(FundLoadAttempt.new({ "id" => "1", "customer_id" => "123", "load_amount" => "$1000", "time" => "2025-05-29T10:00:00Z" }), 1000.0)
    repository.save(FundLoadAttempt.new({ "id" => "2", "customer_id" => "123", "load_amount" => "$500", "time" => "2025-05-29T12:00:00Z" }), 500.0)
  end

  describe '#call' do
    context 'when the daily count is below the limit' do
      let(:context) do
        {
          history: repository.history_for("123")
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$300", "time" => "2025-05-29T14:00:00Z" }) }

      it 'allows the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(true)
      end
    end

    context 'when the daily count is at the limit' do
      before do
        repository.save(FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$300", "time" => "2025-05-29T14:00:00Z" }), 300.0)
      end

      let(:context) do
        {
          history: repository.history_for("123")
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "4", "customer_id" => "123", "load_amount" => "$200", "time" => "2025-05-29T16:00:00Z" }) }

      it 'rejects the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(false)
      end
    end

    context 'when the daily count exceeds the limit' do
      before do
        repository.save(FundLoadAttempt.new({ "id" => "3", "customer_id" => "123", "load_amount" => "$300", "time" => "2025-05-29T14:00:00Z" }), 300.0)
        repository.save(FundLoadAttempt.new({ "id" => "4", "customer_id" => "123", "load_amount" => "$200", "time" => "2025-05-29T16:00:00Z" }), 200.0)
      end

      let(:context) do
        {
          history: repository.history_for("123")
        }
      end
      let(:attempt) { FundLoadAttempt.new({ "id" => "5", "customer_id" => "123", "load_amount" => "$100", "time" => "2025-05-29T18:00:00Z" }) }

      it 'rejects the transaction' do
        result = strategy.call(attempt, context)
        expect(result).to eq(false)
      end
    end
  end
end