require 'coin_bank'

class Vending
  MISSING_PRODUCT_MSG = 'Product is not available'
  NOT_ENOUGH_MONEY_MSG = 'Not enough money'

  class ProductMissing < StandardError; end
  class NotEnoughDeposit < StandardError; end

  attr_reader :products, :deposit

  def initialize(products:, coin_bank:)
    @products = products
    @coin_bank = coin_bank
    @deposit = 0
  end

  def insert_coin(coin)
    add_coin_to_coin_bank!(coin)
    add_coin_to_deposit(coin)
  rescue CoinBank::WrongCoin => e
    return e.message
  end

  def withdraw_product(product_id)
    load_selected_product(product_id)
    validate_product_presence!
    validate_deposit_amount!
    load_change!
    reduce_product_stock
    clear_deposit
    { product: @selected_product[:name], change: humanized_change }
  rescue ProductMissing, NotEnoughDeposit, CoinBank::NotEnoughChange => e
    return e.message
  end

  private

  def load_change!
    @change = @coin_bank.load_change!(@deposit, @selected_product[:price])
  end

  def add_coin_to_coin_bank!(coin)
    @coin_bank.add_coin!(coin)
  end

  def humanized_change
    @change.reduce('') { |acc, (k,v)| acc += "#{k} * #{v}; " }.strip
  end

  def reduce_product_stock
    @selected_product[:stock] -= 1
  end

  def clear_deposit
    @deposit = 0
  end

  def validate_deposit_amount!
    if @deposit < @selected_product[:price]
      raise NotEnoughDeposit.new(NOT_ENOUGH_MONEY_MSG)
    end
  end

  def validate_product_presence!
    if !@selected_product || @selected_product[:stock].zero?
      raise ProductMissing.new(MISSING_PRODUCT_MSG)
    end
  end

  def load_selected_product(product_id)
    @selected_product = @products[product_id]
  end

  def add_coin_to_deposit(coin)
    @deposit += coin
  end
end
