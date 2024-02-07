class CoinBank
  DEFAULT_COINS = { 25 => 0, 50 => 0, 100 => 0, 200 => 0, 300 => 0, 500 => 0 }
  WRON_COIN_MSG = 'Non supported coin'
  NOT_ENOUGH_CHANGE = 'Not enough change'

  class WrongCoin < StandardError; end
  class NotEnoughChange < StandardError; end

  attr_reader :coins

  def initialize(coins:)
    @coins = DEFAULT_COINS.merge(coins)
  end

  def add_coin!(coin)
    validate_coin!(coin)
    add_coin_to_coins(coin)
  end

  def load_change!(deposit, product_price)
    change = {}
    required_change = deposit - product_price

    return change if required_change.zero?

    coins_after_change = @coins.dup
    DEFAULT_COINS.keys.reverse.each do |coin|
      next if coin > required_change

      coins_required = required_change / coin
      coins_to_pick = [coins_required, coins_after_change[coin]].min

      next if coins_to_pick.zero?

      coins_after_change[coin] -= coins_to_pick
      required_change -= coin * coins_to_pick
      change[coin] = coins_to_pick
    end

    raise NotEnoughChange.new(NOT_ENOUGH_CHANGE) unless required_change.zero?

    @coins = coins_after_change
    change
  end

  private

  def validate_coin!(coin)
    raise WrongCoin.new(WRON_COIN_MSG) unless DEFAULT_COINS.keys.include?(coin)
  end

  def add_coin_to_coins(coin)
    @coins[coin] += 1
  end
end
