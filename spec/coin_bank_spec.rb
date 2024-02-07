require 'coin_bank'

RSpec.describe CoinBank do
  subject do
    described_class.new(coins: initial_coins)
  end

  let(:initial_coins) { {} }

  describe '#load_change!' do
    let(:deposit) { 500 }
    let(:product_price) { 200 }

    context 'when not enough change' do
      let(:initial_coins) { { 500 => 1 } }

      it 'raises error' do
        expect { subject.load_change!(deposit, product_price) }
          .to raise_error(described_class::NotEnoughChange)
      end
    end

    context 'when change present' do
      let(:initial_coins) { { 25 => 10, 100 => 10, 200 => 10 } }
      let(:coins_left) do
        described_class::DEFAULT_COINS.merge({ 25 => 8, 100 => 10, 200 => 9 })
      end
      let(:product_price) { 250 }

      it 'returns change' do
        expect(subject.load_change!(deposit, product_price))
          .to eq({ 25 => 2, 200 => 1 })
      end

      it 'updates coins' do
        subject.load_change!(deposit, product_price)
        expect(subject.coins).to eq(coins_left)
      end
    end
  end

  describe '#add_coin!' do
    context 'when coin is invalid' do
      let(:invalid_coin) { 999 }

      it 'raises error' do
        expect { subject.add_coin!(invalid_coin) }
          .to raise_error(described_class::WrongCoin)
      end
    end

    context 'when coin is valid' do
      let(:valid_coin) { described_class::DEFAULT_COINS.keys.first }

      it 'adds coin to coins' do
        subject.add_coin!(valid_coin)
        expect(subject.coins[valid_coin]).to eq(1)
      end
    end
  end
end
