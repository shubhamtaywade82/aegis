# frozen_string_literal: true

require "json"
require "faraday"

module Ai
  class ProviderRouter
    attr_reader :provider, :model, :endpoint

    def initialize(provider: :ollama, model: "llama3.1", endpoint: nil)
      @provider = provider.to_sym
      @model = model
      @endpoint = endpoint || ENV.fetch("OLLAMA_URL", "http://localhost:11434")
    end

    def generate(prompt, system_prompt: nil)
      return simulated_response(prompt) if ENV["RAILS_ENV"] == "test" || @provider == :simulated

      begin
        response = connection.post("/api/generate") do |req|
          req.body = JSON.generate({
            model: model,
            prompt: prompt,
            system: system_prompt,
            stream: false
          })
        end

        if response.success?
          data = JSON.parse(response.body)
          data["response"]
        else
          "Error: LLM request failed with status #{response.status}"
        end
      rescue StandardError => e
        "Error: Failed to connect to LLM provider: #{e.message}"
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: @endpoint) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end

    def simulated_response(prompt)
      case prompt
      when /validate/i, /evaluate/i
        JSON.generate({
          advisory_score: 85,
          concerns: [ "Funding rate slightly elevated" ],
          approved: true
        })
      when /narrative/i, /SOLUSDT/
        "Simulated narrative: Bullish continuation setup on SOLUSDT. Liquidity swept at Asian lows."
      when /journal/i, /closed trades/i
        "Simulated analysis: High win rate on long entries following structure break; low ADX periods underperformed."
      else
        "Simulated response for: #{prompt[0..50]}"
      end
    end
  end
end
