# frozen_string_literal: true

require "json"

module Ai
  class NarrativeGenerator
    def initialize(provider_router:)
      @router = provider_router
    end

    def build_narrative(symbol:, side:, entry_price:, stop_loss:, take_profit:, market_context: {})
      prompt = <<~PROMPT
        Generate a concise, professional trading narrative for the following signal setup:
        Symbol: #{symbol}
        Side: #{side.to_s.upcase}
        Entry: #{entry_price}
        Stop Loss: #{stop_loss}
        Take Profit: #{take_profit}
        Market Context: #{market_context.to_json}
      PROMPT

      system_prompt = "You are a professional quant analyst. Expose trade confluences, major structural shifts, and primary risks concisely."

      @router.generate(prompt, system_prompt: system_prompt)
    end
  end
end
