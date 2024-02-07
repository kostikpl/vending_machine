require 'vending'
require 'securerandom'

RSpec.describe Vending do
  subject do
    described_class.new(products: products, coin_bank: coin_bank)
  end

  let(:product) { { name: 'coke', stock: 1, price: 200 } }
  let(:product_id) { SecureRandom.uuid }
  let(:products) { { product_id => product } }
  let(:coin_bank) { CoinBank.new(coins: { 25 => 100 }) }

  shared_examples 'returns product' do
    it do
      expect(subject.withdraw_product(product_id))
        .to include({ product: product[:name] })
    end
  end

  shared_examples 'reduces product stock' do
    it do
      subject.withdraw_product(product_id)
      product_in_stock =
        subject.products[product_id]

      expect(product_in_stock[:stock]).to eq(0)
    end
  end

  shared_examples 'reduces deposit' do
    it do
      subject.withdraw_product(product_id)
      expect(subject.deposit).to eq(0)
    end
  end

  describe '#insert_coin' do
    let(:coin_to_insert) { 25 }

    it 'inserts coin to coin bank' do
      expect_any_instance_of(CoinBank)
        .to receive(:add_coin!).with(coin_to_insert).and_call_original

      subject.insert_coin(coin_to_insert)
    end

    it 'adds coin value to deposit' do
      subject.insert_coin(coin_to_insert)
      expect(subject.deposit).to eq(coin_to_insert)
    end
  end

  describe '#withdraw_product' do
    context 'when product is absent' do
      let(:product) { { name: 'coke', stock: 0, price: 200 } }

      before do
        subject.insert_coin(product[:price])
      end

      context 'when product stock is zero' do
        it 'returns an error' do
          expect(subject.withdraw_product(product_id))
            .to eq(described_class::MISSING_PRODUCT_MSG)
        end
      end

      context 'when product is not listed' do
        let(:non_existing_id) { SecureRandom.uuid }

        it 'returns an error' do
          expect(subject.withdraw_product(non_existing_id))
            .to eq(described_class::MISSING_PRODUCT_MSG)
        end
      end
    end

    context 'when product is present' do
      context 'when deposit is lower than product price' do
        it 'returns error message' do
          expect(subject.withdraw_product(product_id))
            .to eq(described_class::NOT_ENOUGH_MONEY_MSG)
        end
      end

      context 'when deposit match product price' do
        before do
          subject.insert_coin(200)
        end

        it_behaves_like 'reduces product stock'
        it_behaves_like 'reduces deposit'
        it_behaves_like 'returns product'

        it 'returns an empty change' do
          expect(subject.withdraw_product(product_id))
            .to include({ change: '' })
        end
      end

      context 'when deposit is greater then product price' do
        context 'when not enough change' do
          let(:coin_bank) { CoinBank.new(coins: { 25 => 1, 500 => 1 }) }

          before do
            subject.insert_coin(500)
          end

          it 'returns error message' do
            expect(subject.withdraw_product(product_id))
              .to eq(CoinBank::NOT_ENOUGH_CHANGE)
          end
        end

        context 'when there is change' do
          let(:product) { { name: 'coke', stock: 1, price: 200 } }
          let(:coin_bank) { CoinBank.new(coins: { 25 => 10, 100 => 10, 500 => 5 }) }
          let(:expected_change) { '500 * 1; 25 * 2;' }

          before do
            subject.insert_coin(500)
            subject.insert_coin(200)
            subject.insert_coin(25)
            subject.insert_coin(25)
          end

          it_behaves_like 'reduces product stock'
          it_behaves_like 'reduces deposit'
          it_behaves_like 'returns product'

          it 'returns change' do
            expect(subject.withdraw_product(product_id))
              .to include({ change: expected_change })
          end
        end
      end
    end
  end
end
