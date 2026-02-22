module ProductImport
  class FromScreenshot
    Result = Struct.new(:data, :error, keyword_init: true)

    PROMPT = <<~PROMPT.freeze
      You are analyzing a vendor product screenshot for a furniture store.
      Extract product information visible in the image and return ONLY a valid JSON object with these keys:
      {
        "name": "Full product name",
        "brand": "Vendor brand name (e.g. Ashley Furniture or Generation Trade)",
        "sku": "SKU or model number",
        "short_description": "1-2 sentence summary",
        "description": "Full product description as plain text",
        "color": "Primary color(s)",
        "material": "Primary material(s)",
        "weight": 85.0,
        "dimensions_width": 60.0,
        "dimensions_height": 36.0,
        "dimensions_depth": 18.0,
        "base_cost": 299.00
      }
      Use null for any field not visible in the screenshot.
      Weight must be a number in pounds. Dimensions must be numbers in inches. base_cost must be a number with no $ sign.
      Return ONLY the JSON object — no markdown code fences, no explanation text.
    PROMPT

    def self.call(screenshot_file:)
      new(screenshot_file:).call
    end

    def initialize(screenshot_file:)
      @file = screenshot_file
    end

    def call
      image_data = Base64.strict_encode64(@file.read)
      media_type = @file.content_type.presence_in(%w[image/jpeg image/png image/gif image/webp]) || "image/jpeg"

      client   = Anthropic::Client.new
      response = client.messages.create(
        model:      "claude-opus-4-6",
        max_tokens: 1024,
        messages: [ {
          role:    "user",
          content: [
            { type: "image", source: { type: "base64", media_type: media_type, data: image_data } },
            { type: "text",  text: PROMPT }
          ]
        } ]
      )

      raw  = response.content.first.text.strip
      data = JSON.parse(raw)
      Result.new(data: data)
    rescue JSON::ParserError => e
      Result.new(error: "Could not parse AI response: #{e.message}")
    rescue => e
      Result.new(error: e.message)
    end
  end
end
