module PrimeUtils
  def self.prime?(n)
    return false if n <= 1
    return true if n == 2
    return false if n.even?

    (3..Math.sqrt(n).to_i).step(2).none? { |i| n % i == 0 }
  end
end
