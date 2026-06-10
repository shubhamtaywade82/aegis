# frozen_string_literal: true

require "json"

module Ai
  class JournalAnalyzer
    def initialize(provider_router:)
      @router = provider_router
    end

    def analyze_trades(closed_trades)
      serialized_trades = closed_trades.map do |t|
        {
          entry_price: t.entry_price.to_f,
          exit_price: t.exit_price.to_f,
          quantity: t.quantity.to_f,
          realized_pnl: t.realized_pnl.to_f,
          exit_reason: t.exit_reason
        }
      end

      prompt = <<~PROMPT
        Analyze these closed trades and summarize the key performance insights, clustering of losses, and actionable recommendations:
        #{serialized_trades.to_json}
      PROMPT

      system_prompt = "You are a Chief Investment Officer agent reviewing the trading journal. Extract statistical tendencies and structural failure points."

      @router.generate(prompt, system_prompt: system_prompt)
    end
  end
end
