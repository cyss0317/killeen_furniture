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
          'sku' => sku,
          'name' => 'Test Sofa',
          'description' => 'A nice test sofa',
          'brand' => 'Ashley',
          'images' => [{ 'url' => 'http://example.com/image1.png' }]
        }
      end

      before do
        allow(client_instance).to receive(:get_product).with(sku).and_return(product_data)
      end

      it 'creates a new Furniture record if it does not exist' do
        expect { service.call }.to change(Furniture, :count).by(1)

        furniture = Furniture.last
        expect(furniture.sku).to eq(sku)
        expect(furniture.name).to eq('Test Sofa')
        expect(furniture.description).to eq('A nice test sofa')
        expect(furniture.brand).to eq('Ashley')
        expect(furniture.image_urls).to eq(['http://example.com/image1.png'])
        expect(furniture.ashley_payload).to eq(product_data)
      end

      it 'updates an existing Furniture record' do
        existing_furniture = Furniture.create!(sku: sku, name: 'Old Name')

        expect { service.call }.to not_change(Furniture, :count)

        existing_furniture.reload
        expect(existing_furniture.name).to eq('Test Sofa')
        expect(existing_furniture.ashley_payload).to eq(product_data)
      end
    end

    context 'when there are missing fields in the payload' do
      let(:product_data) do
        {
          'sku' => sku,
          'name' => nil, # missing
        }
      end

      before do
        allow(client_instance).to receive(:get_product).with(sku).and_return(product_data)
      end

      it 'safely handles missing fields preserving defaults or existing values' do
        existing_furniture = Furniture.create!(sku: sku, name: 'Existing Name')

        service.call
        existing_furniture.reload

        # Keeps existing name if nil provided
        expect(existing_furniture.name).to eq('Existing Name')
        expect(existing_furniture.image_urls).to eq([])
      end
    end

    context 'when the client raises a not found error' do
      before do
        allow(client_instance).to receive(:get_product).with(sku)
          .and_raise(Ashley::Client::RecordNotFoundError, 'Not found')
      end

      it 'raises the error without saving' do
        expect { service.call }.to raise_error(Ashley::Client::RecordNotFoundError)
      end
    end

    context 'when the client raises an error due to malformed response' do
      before do
        allow(client_instance).to receive(:get_product).with(sku)
          .and_raise(Ashley::Client::Error, 'Malformed response')
      end

      it 'logs the error and raises' do
        expect(Rails.logger).to receive(:error).with(/\[Ashley::ProductSyncService\] Error syncing SKU SKUTEST: Malformed response/)
        expect { service.call }.to raise_error(Ashley::Client::Error)
      end
    end
  end
end
