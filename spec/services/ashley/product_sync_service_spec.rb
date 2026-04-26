require 'rails_helper'

RSpec.describe Ashley::ProductSyncService do
  let(:sku) { 'SKUTEST' }
  let(:service) { described_class.new(sku) }
  let(:client_instance) { instance_double(Ashley::Client) }

  before do
    allow(Ashley::Client).to receive(:new).and_return(client_instance)
  end

  describe '#call' do
    context 'when the API request is successful' do
      let(:product_data) do
        {
          'sku'    => sku,
          'name'   => 'Test Sofa',
          'brand'  => 'Ashley',
          'images' => [ { 'url' => 'https://example.com/image1.png' } ]
        }
      end

      before do
        allow(client_instance).to receive(:get_product).with(sku).and_return(product_data)
      end

      context 'when the Product already exists' do
        let!(:product) { create(:product, sku: sku) }

        it 'does not create a new Product record' do
          expect { service.call }.not_to change(Product, :count)
        end

        it 'updates name and brand from the API payload' do
          service.call
          product.reload
          expect(product.name).to eq('Test Sofa')
          expect(product.brand).to eq('Ashley')
        end

        it 'maps the images array to vendor_image_urls' do
          service.call
          product.reload
          expect(product.vendor_image_urls).to eq([ 'https://example.com/image1.png' ])
        end

        it 'stores the raw API payload in ashley_payload' do
          service.call
          product.reload
          expect(product.ashley_payload).to eq(product_data)
        end

        it 'returns the updated product' do
          result = service.call
          expect(result).to eq(product)
        end
      end

      context 'when no Product exists for the SKU' do
        # Product requires base_cost and category which the Ashley API does not provide,
        # so find_or_initialize_by produces a record that fails validation on save.
        it 'raises ActiveRecord::RecordInvalid' do
          expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when the payload contains nil fields' do
      let(:product_data) do
        {
          'sku'    => sku,
          'name'   => nil,
          'images' => []
        }
      end
      let!(:product) { create(:product, sku: sku, name: 'Existing Name') }

      before do
        allow(client_instance).to receive(:get_product).with(sku).and_return(product_data)
      end

      it 'preserves the existing name when the API returns nil' do
        service.call
        product.reload
        expect(product.name).to eq('Existing Name')
      end

      it 'sets vendor_image_urls to an empty array when images is empty' do
        service.call
        product.reload
        expect(product.vendor_image_urls).to eq([])
      end
    end

    context 'when the client raises RecordNotFoundError' do
      before do
        allow(client_instance).to receive(:get_product).with(sku)
          .and_raise(Ashley::Client::RecordNotFoundError, 'Not found')
      end

      # RecordNotFoundError < Error, so the rescue block logs it and re-raises.
      it 'logs the error and re-raises RecordNotFoundError' do
        expect(Rails.logger).to receive(:error)
          .with(/\[Ashley::ProductSyncService\] Error syncing SKU SKUTEST: Not found/)
        expect { service.call }.to raise_error(Ashley::Client::RecordNotFoundError)
      end
    end

    context 'when the client raises a generic Error' do
      before do
        allow(client_instance).to receive(:get_product).with(sku)
          .and_raise(Ashley::Client::Error, 'Malformed response')
      end

      it 'logs the error and re-raises' do
        expect(Rails.logger).to receive(:error)
          .with(/\[Ashley::ProductSyncService\] Error syncing SKU SKUTEST: Malformed response/)
        expect { service.call }.to raise_error(Ashley::Client::Error)
      end
    end
  end
end
