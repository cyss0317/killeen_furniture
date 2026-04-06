require 'rails_helper'

RSpec.describe Ashley::Client do
  let(:client) { described_class.new }
  let(:sku) { '12345' }

  describe '#get_product' do
    context 'when the API call is successful' do
      let(:response_body) { { 'sku' => sku, 'name' => 'Sofa' }.to_json }

      before do
        stub_request(:get, "#{described_class::BASE_URL}/api/v1/products/#{sku}")
          .with(headers: { 'Authorization' => "Bearer #{described_class::CREDENTIAL}" })
          .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the parsed JSON product data' do
        result = client.get_product(sku)
        expect(result['sku']).to eq(sku)
        expect(result['name']).to eq('Sofa')
      end
    end

    context 'when the product is not found' do
      before do
        stub_request(:get, "#{described_class::BASE_URL}/api/v1/products/#{sku}")
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises a RecordNotFoundError' do
        expect { client.get_product(sku) }.to raise_error(Ashley::Client::RecordNotFoundError, "Product not found for SKU: #{sku}")
      end
    end

    context 'when the API returns a server error' do
      before do
        stub_request(:get, "#{described_class::BASE_URL}/api/v1/products/#{sku}")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an Ashley::Client::Error' do
        expect { client.get_product(sku) }.to raise_error(Ashley::Client::Error, /Ashley API error: 500/)
      end
    end

    context 'when the connection fails timeout' do
      before do
        stub_request(:get, "#{described_class::BASE_URL}/api/v1/products/#{sku}")
          .to_timeout
      end

      it 'raises an Ashley::Client::Error for faraday error' do
        expect { client.get_product(sku) }.to raise_error(Ashley::Client::Error, /Faraday connection error:/)
      end
    end
  end
end
