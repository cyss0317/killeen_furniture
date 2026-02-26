require 'rails_helper'

RSpec.describe PurchaseOrders::ImportScreenshot do
  let(:mock_client) { instance_double(Anthropic::Client) }
  let(:mock_messages) { instance_double("messages") }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:messages).and_return(mock_messages)
  end

  describe '#call' do
    let(:file) { fixture_file_upload(Rails.root.join('public', 'icon.png'), 'image/png') }
    let(:user) { User.create!(email: "test@example.com", password: "password", first_name: "Test", last_name: "User") }
    let(:params) do
      {
        file: file,
        created_by: user,
      }
    end

    context 'when AI returns Ashley Furniture as supplier' do
      let(:mock_response) do
        {
          "supplier" => "ashley",
          "invoice_number" => "ASH-123",
          "items" => [
            {
              "item_code" => "B1190-31",
              "description" => "Six Drawer Dresser",
              "series" => "Gerridan",
              "color" => "White/Gray",
              "qty" => 1,
              "price" => 189.50
            }
          ]
        }.to_json
      end

      before do
        allow(mock_messages).to receive(:create).and_return(
          double(content: [double(text: mock_response)])
        )
      end

      it 'extracts Ashley Furniture as supplier and creates PO' do
        result = described_class.call(**params)

        expect(result).to be_success
        expect(result.purchase_order.reference_number).to eq("ASH-123")
        expect(result.purchase_order.brand).to eq("Ashley Furniture")

        product = Product.find_by(sku: "B1190-31")
        expect(product.category.name).to eq("Ashley Furniture")
      end
    end

    context 'when AI returns Generation Trade as supplier' do
      let(:mock_response) do
        {
          "supplier" => "generation_trade",
          "invoice_number" => "GT-456",
          "items" => [
            {
              "item_code" => "GT-999",
              "description" => "Accent Chair",
              "series" => "",
              "color" => "Gray",
              "qty" => 2,
              "price" => 245.00
            }
          ]
        }.to_json
      end

      before do
        allow(mock_messages).to receive(:create).and_return(
          double(content: [double(text: mock_response)])
        )
        # Mock the enrichment so it doesn't actually try to fetch
        allow(Products::FetchFromGenerationTrade).to receive(:enrich!)
      end

      it 'extracts Generation Trade as supplier and creates PO' do
        result = described_class.call(**params)

        expect(result).to be_success
        expect(result.purchase_order.reference_number).to eq("GT-456")
        expect(result.purchase_order.brand).to eq("Generation Trade")

        product = Product.find_by(sku: "GT-999")
        expect(product.category.name).to eq("Generation Trade")
        expect(Products::FetchFromGenerationTrade).to have_received(:enrich!).with(product, series: "", description: "Accent Chair")
      end
    end

    context 'when AI omits supplier' do
      let(:mock_response) do
        {
          "invoice_number" => "DEF-789",
          "items" => [
            {
              "item_code" => "UNK-111",
              "description" => "Table",
              "series" => "",
              "color" => "",
              "qty" => 1,
              "price" => 100.00
            }
          ]
        }.to_json
      end

      before do
        allow(mock_messages).to receive(:create).and_return(
          double(content: [double(text: mock_response)])
        )
        allow(Products::FetchFromAshley).to receive(:enrich!)
      end

      it 'defaults to Ashley Furniture' do
        result = described_class.call(**params)

        expect(result).to be_success
        expect(result.purchase_order.brand).to eq("Ashley Furniture")

        product = Product.find_by(sku: "UNK-111")
        expect(product.category.name).to eq("Ashley Furniture")
        expect(Products::FetchFromAshley).to have_received(:enrich!)
      end
    end
  end
end
