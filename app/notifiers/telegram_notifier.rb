# frozen_string_literal: true

module Notifiers
  class TelegramNotifier
    attr_reader :sent_messages

    def initialize(token: nil, chat_id: nil)
      @token = token
      @chat_id = chat_id
      @sent_messages = []
    end

    def notify(alert)
      emoji = case alert[:severity].to_sym
      when :info then "ℹ"
      when :warning then "⚠"
      when :critical then "🛑"
      when :emergency then "🚨"
      else "🔔"
      end

      msg = "#{emoji} Alert: #{alert[:message]}"
      send_message(msg)
    end

    def notify_position_opened(symbol:, side:, entry:, sl:, tp:, qty:, risk_pct:)
      msg = [
        "🟢 Position Opened",
        "",
        "#{symbol} #{side.to_s.upcase}",
        "",
        "Entry: #{entry}",
        "SL: #{sl}",
        "TP: #{tp}",
        "",
        "Qty: #{qty}",
        "Risk: #{risk_pct}%"
      ].join("\n")

      send_message(msg)
    end

    def notify_position_closed(symbol:, pnl:, equity:)
      sign = pnl >= 0 ? "+" : ""
      msg = [
        "🔵 Position Closed",
        "",
        symbol,
        "",
        "PnL: #{sign}$#{pnl}",
        "",
        "Equity: $#{equity}"
      ].join("\n")

      send_message(msg)
    end

    def notify_risk_rejected(symbol:, reason:, usage_pct:, limit_pct:)
      msg = [
        "🛑 Trade Rejected",
        "",
        "Symbol: #{symbol}",
        "",
        "Reason:",
        reason,
        "",
        "Usage:",
        "#{usage_pct}% / #{limit_pct}%"
      ].join("\n")

      send_message(msg)
    end

    def notify_kill_switch
      msg = [
        "🚨 EMERGENCY STOP",
        "",
        "Positions Closed",
        "Orders Cancelled",
        "",
        "Execution Disabled"
      ].join("\n")

      send_message(msg)
    end

    private

    def send_message(text)
      @sent_messages << text

      return true unless TelegramSettings.enabled?

      token = @token || TelegramSettings.bot_token
      chat_id = @chat_id || TelegramSettings.chat_id

      begin
        response = Faraday.post(
          "https://api.telegram.org/bot#{token}/sendMessage",
          { chat_id: chat_id, text: text }.to_json,
          { "Content-Type" => "application/json" }
        )
        response.success?
      rescue StandardError => e
        Rails.logger.error("[TelegramNotifier] Failed to send message: #{e.message}")
        false
      end
    end
  end
end
