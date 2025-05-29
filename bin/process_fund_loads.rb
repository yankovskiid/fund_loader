#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'time'

CONFIG = YAML.load_file(File.join(__dir__, '..', 'config', 'config.yml'))

require_relative '../app/models/fund_load_attempt'
require_relative '../app/repositories/load_history_repository'
require_relative '../app/strategies/daily_limit_strategy'
require_relative '../app/strategies/weekly_limit_strategy'
require_relative '../app/strategies/daily_count_strategy'
require_relative '../app/strategies/prime_sanction_strategy'
require_relative '../app/strategies/monday_sanction_strategy'
require_relative '../app/services/rule_engine'
require_relative '../app/services/fund_load_processor'

repository = LoadHistoryRepository.new

strategies = [
  DailyLimitStrategy.new(CONFIG),
  WeeklyLimitStrategy.new(CONFIG),
  DailyCountStrategy.new(CONFIG),
  PrimeSanctionStrategy.new(CONFIG),
  MondaySanctionStrategy.new(CONFIG)
]

rule_engine = RuleEngine.new(strategies)
processor = FundLoadProcessor.new(rule_engine: rule_engine, repository: repository)

input_file = File.join(__dir__, '..', 'input.txt')
output_file = File.join(__dir__, '..',  'output.txt')

File.open(output_file, 'w') do |out|
  File.foreach(input_file) do |line|
    line.strip!
    next if line.empty?

    begin
      data = JSON.parse(line)
      attempt = FundLoadAttempt.new(data)
      result = processor.process(attempt)
      out.puts JSON.generate(result)
    rescue JSON::ParserError => e
      warn "Skipping invalid JSON line: #{line}"
    end
  end
end

puts "Processing complete. Results written to #{output_file}"
