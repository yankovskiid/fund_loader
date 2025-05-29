require 'time'

class FundLoadAttempt
  attr_reader :id, :customer_id, :amount, :timestamp

  def initialize(data)
    @id = data["id"]
    @customer_id = data["customer_id"]
    @amount = data["load_amount"].gsub("$", "").to_f
    @timestamp = Time.parse(data["time"])
  end

  def date
    @timestamp.to_date
  end
end
