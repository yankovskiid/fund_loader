require 'rspec'
require 'date'
require_relative '../../app/strategies/monday_sanction_strategy'

RSpec.describe MondaySanctionStrategy do
  let(:config) do
    {
      'special_sanctions' => { 'monday_multiplier' => 2.0 },
      'fund_load_limits' => { 'daily_limit' => 5000, 'weekly_limit' => 20000 }
    }
  end

  let(:strategy) { MondaySanctionStrategy.new(config) }
  let(:daily_limit_strategy) { instance_double('DailyLimitStrategy') }
  let(:weekly_limit_strategy) { instance_double('WeeklyLimitStrategy') }

  before do
    allow(DailyLimitStrategy).to receive(:new).and_return(daily_limit_strategy)
    allow(WeeklyLimitStrategy).to receive(:new).and_return(weekly_limit_strategy)
  end

  describe '#call' do
    let(:fund_load_attempt) { double(date: date, amount: amount) }
    let(:context) { { history: history } }

    context 'when the date is Monday' do
      let(:date) { Date.new(2025, 5, 26) } # Monday
      let(:amount) { 1000 }
      let(:history) { [] }

      before do
        allow(daily_limit_strategy).to receive(:call).and_return(true)
        allow(weekly_limit_strategy).to receive(:call).and_return(true)
      end

      it 'applies the Monday multiplier to the effective amount' do
        strategy.call(fund_load_attempt, context)
        expect(context[:effective_amount]).to eq(2000)
      end

      it 'returns true if both strategies allow the transaction' do
        result = strategy.call(fund_load_attempt, context)
        expect(result).to be true
      end
    end

    context 'when the date is not Monday' do
      let(:date) { Date.new(2025, 5, 27) } # Tuesday
      let(:amount) { 1000 }
      let(:history) { [] }

      before do
        allow(daily_limit_strategy).to receive(:call).and_return(true)
        allow(weekly_limit_strategy).to receive(:call).and_return(true)
      end

      it 'does not apply the Monday multiplier to the effective amount' do
        strategy.call(fund_load_attempt, context)
        expect(context[:effective_amount]).to eq(1000)
      end

      it 'returns true if both strategies allow the transaction' do
        result = strategy.call(fund_load_attempt, context)
        expect(result).to be true
      end
    end

    context 'when daily limit strategy rejects the transaction' do
      let(:date) { Date.new(2025, 5, 26) } # Monday
      let(:amount) { 1000 }
      let(:history) { [] }

      before do
        allow(daily_limit_strategy).to receive(:call).and_return(false)
      end

      it 'returns false' do
        result = strategy.call(fund_load_attempt, context)
        expect(result).to be false
      end
    end

    context 'when weekly limit strategy rejects the transaction' do
      let(:date) { Date.new(2025, 5, 26) } # Monday
      let(:amount) { 1000 }
      let(:history) { [] }

      before do
        allow(daily_limit_strategy).to receive(:call).and_return(true)
        allow(weekly_limit_strategy).to receive(:call).and_return(false)
      end

      it 'returns false' do
        result = strategy.call(fund_load_attempt, context)
        expect(result).to be false
      end
    end
  end
end