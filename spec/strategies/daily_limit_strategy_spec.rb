require 'rspec'
require_relative '../../app/strategies/daily_limit_strategy'

RSpec.describe DailyLimitStrategy do
  let(:config) { { 'fund_load_limits' => { 'daily_limit' => 5000 } } }
  let(:strategy) { DailyLimitStrategy.new(config) }

  describe '#call' do
    let(:fund_load_attempt) { double(date: '2023-10-01') }
    let(:context) do
      {
        effective_amount: effective_amount,
        history: history
      }
    end

    context 'when daily total is below the limit' do
      let(:effective_amount) { 1000 }
      let(:history) { [{ date: '2023-10-01', effective_amount: 3000 }] }

      it 'returns true' do
        expect(strategy.call(fund_load_attempt, context)).to be true
      end
    end

    context 'when daily total exceeds the limit' do
      let(:effective_amount) { 3000 }
      let(:history) { [{ date: '2023-10-01', effective_amount: 3000 }] }

      it 'returns false' do
        expect(strategy.call(fund_load_attempt, context)).to be false
      end
    end

    context 'when there are no previous attempts for the day' do
      let(:effective_amount) { 2000 }
      let(:history) { [] }

      it 'returns true' do
        expect(strategy.call(fund_load_attempt, context)).to be true
      end
    end
  end
end
