# frozen_string_literal: true

require "json"

module AI
  class Validator
    def initialize(provider_router:)
      @router = provider_router
    end

    def validate_setup(order_request:, indicators:, market_context: {})
      prompt = <<~PROMPT
        Evaluate this trading setup and return a JSON object containing:
        1. "advisory_score": Integer between 0 and 100 indicating confidence.
        2. "concerns": Array of strings listing specific risk factors.
        3. "approved": Boolean value.

        Order Request:
        - Symbol: #{order_request.symbol}
        - Side: #{order_request.side}
        - Qty: #{order_request.quantity.to_f}

        Technical Indicators:
        #{indicators.to_json}

        Market Context:
        #{market_context.to_json}
      PROMPT

      system_prompt = "You are a risk officer agent. Analyze the setup and respond ONLY with a raw JSON object containing 'advisory_score', 'concerns', and 'approved'."

      res = @router.generate(prompt, system_prompt: system_prompt)
      parse_json_response(res)
    end

    private

    def parse_json_response(raw_response)
      JSON.parse(raw_response, symbolize_names: true)
    rescue JSON::ParserError
      {
        advisory_score: 50,
        concerns: [ "Failed to parse AI response. Operating on safety fallback." ],
        approved: true
      }
    end
  end
end
