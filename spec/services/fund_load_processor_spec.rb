require 'rspec'
require_relative '../../app/services/fund_load_processor'
require_relative '../../app/models/fund_load_attempt'
require_relative '../../app/repositories/load_history_repository'
require_relative '../../app/services/rule_engine'
require_relative '../../app/strategies/daily_limit_strategy'
require_relative '../../app/strategies/weekly_limit_strategy'
require_relative '../../app/strategies/daily_count_strategy'
require_relative '../../app/strategies/prime_sanction_strategy'
require_relative '../../app/strategies/monday_sanction_strategy'

RSpec.describe FundLoadProcessor do
  subject(:processor) { described_class.new(rule_engine: rule_engine, repository: repository) }

  let(:repository) { LoadHistoryRepository.new }
  let(:config) do
    {
      'fund_load_limits' => {
        'daily_limit' => 5000.0,
        'weekly_limit' => 20_000.0,
        'daily_load_count_limit' => 3
      },
      'special_sanctions' => {
        'prime_id' => {
          'max_amount' => 9999.0,
          'max_attempts_per_day' => 1
        },
        'monday_multiplier' => 2
      }
    }
  end
  let(:strategies) do
    [
      DailyLimitStrategy.new(config),
      WeeklyLimitStrategy.new(config),
      DailyCountStrategy.new(config),
      PrimeSanctionStrategy.new(config),
      MondaySanctionStrategy.new(config)
    ]
  end
  let(:rule_engine) { RuleEngine.new(strategies) }
  let(:valid_attempt_data) do
    {
      'id' => '123',
      'customer_id' => '999',
      'load_amount' => '$1000.00',
      'time' => '2025-05-26T12:00:00Z'
    }
  end

  describe '#process' do
    context 'when the fund load attempt is valid' do
      it 'accepts the attempt' do
        attempt = FundLoadAttempt.new(valid_attempt_data)
        result = processor.process(attempt)
        expect(result[:accepted]).to be true
      end
    end

    context 'when the daily limit is exceeded' do
      let(:customer_id) { '999' }

      before do
        5.times do
          processor.process(FundLoadAttempt.new({
            'id' => "id_#{rand(1000)}",
            'customer_id' => customer_id,
            'load_amount' => '$1000.00',
            'time' => '2025-05-26T10:00:00Z'
          }))
        end
      end

      it 'rejects the attempt' do
        attempt = FundLoadAttempt.new({
          'id' => 'exceed_1',
          'customer_id' => customer_id,
          'load_amount' => '$1000.00',
          'time' => '2025-05-26T12:00:00Z'
        })

        result = processor.process(attempt)
        expect(result[:accepted]).to be false
      end
    end

    context 'when the daily load count is exceeded' do
      let(:customer_id) { '888' }

      before do
        3.times do |i|
          processor.process(FundLoadAttempt.new({
            'id' => "id_#{i}",
            'customer_id' => customer_id,
            'load_amount' => '$100.00',
            'time' => '2025-05-26T08:00:00Z'
          }))
        end
      end

      it 'rejects the attempt' do
        attempt = FundLoadAttempt.new({
          'id' => 'exceed_count',
          'customer_id' => customer_id,
          'load_amount' => '$50.00',
          'time' => '2025-05-26T10:00:00Z'
        })

        result = processor.process(attempt)
        expect(result[:accepted]).to be false
      end
    end

    context 'when the monday sanction applies' do
      it 'doubles the effective amount for Monday loads' do
        monday_attempt = FundLoadAttempt.new({
          'id' => 'monday1',
          'customer_id' => '777',
          'load_amount' => '$2000.00',
          'time' => '2025-05-26T09:00:00Z' # Monday
        })
        result = processor.process(monday_attempt)
        expect(result[:accepted]).to be true

        history = repository.history_for('777')
        expect(history.last[:effective_amount]).to eq(4000.0) # doubled by sanction
      end

      it 'rejects the attempt if the doubled effective amount exceeds the daily limit' do
        monday_attempt = FundLoadAttempt.new({
          'id' => 'monday2',
          'customer_id' => '777',
          'load_amount' => '$4000.00',
          'time' => '2025-05-26T09:00:00Z' # Monday
        })
        result = processor.process(monday_attempt)
        expect(result[:accepted]).to be false
      end

      it 'rejects the attempt if the doubled effective amount exceeds the weekly limit' do
        # Fill up the weekly limit
        6.times do |i|
          processor.process(FundLoadAttempt.new({
            'id' => "id_#{i}",
            'customer_id' => '777',
            'load_amount' => '$3000.00',
            'time' => '2025-05-25T10:00:00Z'
          }))
        end

        monday_attempt = FundLoadAttempt.new({
          'id' => 'monday3',
          'customer_id' => '777',
          'load_amount' => '$3000.00',
          'time' => '2025-05-26T09:00:00Z' # Monday
        })
        result = processor.process(monday_attempt)
        expect(result[:accepted]).to be false
      end

      it 'does not modify the effective amount for non-Monday loads' do
        non_monday_attempt = FundLoadAttempt.new({
          'id' => 'non_monday1',
          'customer_id' => '777',
          'load_amount' => '$3000.00',
          'time' => '2025-05-27T09:00:00Z' # Tuesday
        })
        result = processor.process(non_monday_attempt)
        expect(result[:accepted]).to be true

        history = repository.history_for('777')
        expect(history.last[:effective_amount]).to eq(3000.0) # original amount
      end
    end

    context 'when the prime sanction applies' do
      it 'enforces prime sanction limits' do
        prime_attempt = FundLoadAttempt.new({
          'id' => '17', # prime number
          'customer_id' => '555',
          'load_amount' => '$4000.00',
          'time' => '2025-05-27T09:00:00Z'
        })
        result = processor.process(prime_attempt)
        expect(result[:accepted]).to be true

        prime_attempt2 = FundLoadAttempt.new({
          'id' => '19', # also prime
          'customer_id' => '556',
          'load_amount' => '$1000.00',
          'time' => '2025-05-27T10:00:00Z'
        })
        result2 = processor.process(prime_attempt2)
        expect(result2[:accepted]).to be false
      end
    end

    context 'when the weekly limit is exceeded' do
      let(:customer_id) { '777' }

      before do
        7.times do |i|
          processor.process(FundLoadAttempt.new({
            'id' => "id_#{i}",
            'customer_id' => customer_id,
            'load_amount' => '$3000.00',
            'time' => '2025-05-25T10:00:00Z'
          }))
        end
      end

      it 'rejects the attempt' do
        attempt = FundLoadAttempt.new({
          'id' => 'exceed_weekly',
          'customer_id' => customer_id,
          'load_amount' => '$3000.00',
          'time' => '2025-05-25T12:00:00Z'
        })

        result = processor.process(attempt)
        expect(result[:accepted]).to be false
      end
    end
  end
end
