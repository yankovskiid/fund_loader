require 'rspec'
require_relative '../../app/strategies/prime_sanction_strategy'
require_relative '../../app/models/fund_load_attempt'
require_relative '../../app/utils/prime_utils'

RSpec.describe PrimeSanctionStrategy do
  let(:config) do
    {
      'special_sanctions' => {
        'prime_id' => {
          'max_amount' => 1000
        }
      }
    }
  end
  subject(:strategy) { PrimeSanctionStrategy.new(config) }
  let(:fund_load_attempt) { FundLoadAttempt.new({ "id" => "7", "customer_id" => "123", "load_amount" => "$500", "time" => "2025-05-29T10:00:00Z" }) }
  let(:context) { { date: '2025-05-29', amount: 500, prime_ids: [] } }

  before do
    allow(PrimeUtils).to receive(:prime?).and_return(true)
  end

  describe '#call' do
    context 'when id is not prime' do
      it 'returns true' do
        allow(PrimeUtils).to receive(:prime?).with(7).and_return(false)
        result = strategy.call(fund_load_attempt, context)
        expect(result).to eq(true)
      end
    end

    context 'when date is already in prime_ids' do
      it 'returns false' do
        context[:prime_ids] << '2025-05-29'
        result = strategy.call(fund_load_attempt, context)
        expect(result).to eq(false)
      end
    end

    context 'when amount exceeds max_amount' do
      it 'returns false' do
        context[:amount] = 1500
        result = strategy.call(fund_load_attempt, context)
        expect(result).to eq(false)
      end
    end

    context 'when all conditions are met' do
      it 'adds date to prime_ids and returns true' do
        result = strategy.call(fund_load_attempt, context)
        expect(result).to eq(true)
        expect(context[:prime_ids]).to include('2025-05-29')
      end
    end
  end
end