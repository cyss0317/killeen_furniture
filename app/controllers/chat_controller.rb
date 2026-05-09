class ChatController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a helpful customer service assistant for Warehouse Furniture, a local furniture store in Killeen, Texas.

    Store Information:
    - Name: Warehouse Furniture
    - Address: 1104 E Veterans Memorial Blvd, Killeen, TX 76541
    - Hours: Monday–Saturday 11:00 AM – 6:00 PM, Sunday Closed
    - We carry Ashley Furniture and Generation Trade products
    - We offer local delivery to Killeen, Harker Heights, Copperas Cove, Fort Cavazos, Nolanville, Belton, Florence, Lampasas, Gatesville, and Temple

    What we sell:
    - Sofas, sectionals, recliners, and living room furniture
    - Bedroom sets, beds, dressers, nightstands, and mattresses
    - Dining tables, chairs, and dining sets
    - Accent furniture and home décor

    Financing: We offer financing options — ask in store for details.

    Guidelines:
    - Be friendly, concise, and helpful
    - If asked about specific product availability or pricing, encourage them to call or visit the store
    - Email: info@warehouse-furniture.com
    - If asked something outside your knowledge, suggest emailing info@warehouse-furniture.com or visiting the store in person
    - Do not make up specific prices or stock levels
    - Keep responses short and conversational (2-4 sentences max unless a detailed question requires more)
  PROMPT

  def message
    user_message = params[:message].to_s.strip
    history      = Array(params[:history]).map do |msg|
      { role: msg[:role].to_s, content: msg[:content].to_s }
    end

    return render json: { error: "Please enter a message." }, status: :unprocessable_entity if user_message.blank?

    api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.anthropic_api_key
    return render json: { error: "Chat is unavailable right now." }, status: :service_unavailable if api_key.blank?

    client = Anthropic::Client.new(api_key: api_key)

    messages = history.last(10) + [ { role: "user", content: user_message } ]

    response = client.messages.create(
      model:      "claude-haiku-4-5-20251001",
      max_tokens: 512,
      system:     SYSTEM_PROMPT,
      messages:   messages
    )

    render json: { reply: response.content[0].text.strip }
  rescue => e
    Rails.logger.error "[ChatController] #{e.class}: #{e.message}"
    render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
  end
end
