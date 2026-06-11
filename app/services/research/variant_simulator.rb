# frozen_string_literal: true


module Research
  class VariantSimulator
    DEFAULT_QUANTITY = 1.0
    DEFAULT_FEES     = 0.0

    attr_reader :candles,
                :supertrend,
                :atr,
                :atr_stop_multiplier,
                :reward_risk_ratio,
                :quantity

    def initialize(
      candles:,
      supertrend:,
      atr:,
      atr_stop_multiplier:,
      reward_risk_ratio:,
      quantity: DEFAULT_QUANTITY
    )
      @candles               = candles
      @supertrend            = supertrend
      @atr                   = atr
      @atr_stop_multiplier   = atr_stop_multiplier
      @reward_risk_ratio     = reward_risk_ratio
      @quantity              = quantity

      validate_inputs!
    end

    def call
      trades = []

      position = nil

      candles.each_with_index do |candle, index|
        st = supertrend[index]

        next if st.nil?
        next if index.zero?

        previous_st = supertrend[index - 1]

        next if previous_st.nil?
        next if atr[index].nil?

        #
        # Position Management
        #
        if position
          update_trailing_stop!(
            position: position,
            st: st
          )

          exit_trade =
            evaluate_exit(
              position: position,
              candle: candle,
              previous_st: previous_st,
              current_st: st
            )

          if exit_trade
            trades << exit_trade
            position = nil
          end
        end

        #
        # Prevent duplicate positions
        #
        next if position

        #
        # Entry Logic
        #
        if bullish_flip?(previous_st, st)
          position = build_long_position(
            candle: candle,
            atr_value: atr[index],
            st: st
          )

        elsif bearish_flip?(previous_st, st)
          position = build_short_position(
            candle: candle,
            atr_value: atr[index],
            st: st
          )
        end

        #
        # Forced close on final candle
        #
        if index == candles.size - 1 && position
          trades << close_position(
            position: position,
            candle: candle,
            reason: "end_of_series"
          )

          position = nil
        end
      end

      trades
    end

    private

    PositionState = Struct.new(
      :side,
      :entry_time,
      :entry_price,
      :stop_loss,
      :take_profit,
      :trail_stop,
      keyword_init: true
    )

    def validate_inputs!
      unless candles.size == supertrend.size &&
             candles.size == atr.size
        raise ResearchError,
              "candles, supertrend and atr must have equal sizes"
      end

      unless atr_stop_multiplier.positive?
        raise ResearchError,
              "atr_stop_multiplier must be positive"
      end

      unless reward_risk_ratio.positive?
        raise ResearchError,
              "reward_risk_ratio must be positive"
      end

      unless quantity.positive?
        raise ResearchError,
              "quantity must be positive"
      end
    end

    def bullish_flip?(previous_st, current_st)
      previous_st.direction == :bearish &&
        current_st.direction == :bullish
    end

    def bearish_flip?(previous_st, current_st)
      previous_st.direction == :bullish &&
        current_st.direction == :bearish
    end

    def build_long_position(candle:, atr_value:, st:)
      entry_price = candle.close

      stop_loss =
        entry_price -
        (atr_value * atr_stop_multiplier)

      risk =
        entry_price - stop_loss

      take_profit =
        entry_price +
        (risk * reward_risk_ratio)

      PositionState.new(
        side: :long,
        entry_time: candle.close_time,
        entry_price: entry_price,
        stop_loss: stop_loss,
        take_profit: take_profit,
        trail_stop: st.lower_band
      )
    end

    def build_short_position(candle:, atr_value:, st:)
      entry_price = candle.close

      stop_loss =
        entry_price +
        (atr_value * atr_stop_multiplier)

      risk =
        stop_loss - entry_price

      take_profit =
        entry_price -
        (risk * reward_risk_ratio)

      PositionState.new(
        side: :short,
        entry_time: candle.close_time,
        entry_price: entry_price,
        stop_loss: stop_loss,
        take_profit: take_profit,
        trail_stop: st.upper_band
      )
    end

    def close_position(position:, candle:, reason:)
      Trade.new(
        symbol: "UNKNOWN",
        side: position.side,
        entry_time: position.entry_time,
        exit_time: candle.close_time,
        entry_price: position.entry_price,
        exit_price: candle.close,
        quantity: quantity,
        fees: DEFAULT_FEES,
        reason: reason
      )
    end

    def evaluate_exit(
      position:,
      candle:,
      previous_st:,
      current_st:
    )
      case position.side
      when :long
        evaluate_long_exit(
          position: position,
          candle: candle,
          previous_st: previous_st,
          current_st: current_st
        )

      when :short
        evaluate_short_exit(
          position: position,
          candle: candle,
          previous_st: previous_st,
          current_st: current_st
        )
      end
    end

    def evaluate_long_exit(
      position:,
      candle:,
      previous_st:,
      current_st:
    )
      #
      # 1. ATR Stop
      #
      if candle.low <= position.stop_loss
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.stop_loss,
          reason: "atr_stop"
        )
      end

      #
      # 2. Take Profit
      #
      if candle.high >= position.take_profit
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.take_profit,
          reason: "take_profit"
        )
      end

      #
      # 3. Supertrend Trail
      #
      if candle.low <= position.trail_stop
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.trail_stop,
          reason: "supertrend_trail"
        )
      end

      #
      # 4. Opposite Flip
      #
      if bearish_flip?(previous_st, current_st)
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: candle.close,
          reason: "opposite_flip"
        )
      end

      nil
    end

    def evaluate_short_exit(
      position:,
      candle:,
      previous_st:,
      current_st:
    )
      #
      # 1. ATR Stop
      #
      if candle.high >= position.stop_loss
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.stop_loss,
          reason: "atr_stop"
        )
      end

      #
      # 2. Take Profit
      #
      if candle.low <= position.take_profit
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.take_profit,
          reason: "take_profit"
        )
      end

      #
      # 3. Supertrend Trail
      #
      if candle.high >= position.trail_stop
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: position.trail_stop,
          reason: "supertrend_trail"
        )
      end

      #
      # 4. Opposite Flip
      #
      if bullish_flip?(previous_st, current_st)
        return build_exit_trade(
          position: position,
          candle: candle,
          exit_price: candle.close,
          reason: "opposite_flip"
        )
      end

      nil
    end

    def update_trailing_stop!(position:, st:)
      case position.side
      when :long
        position.trail_stop =
          [
            position.trail_stop,
            st.lower_band
          ].compact.max

      when :short
        position.trail_stop =
          [
            position.trail_stop,
            st.upper_band
          ].compact.min
      end
    end

    def build_exit_trade(
      position:,
      candle:,
      exit_price:,
      reason:
    )
      Trade.new(
        symbol: "UNKNOWN",
        side: position.side,
        entry_time: position.entry_time,
        exit_time: candle.close_time,
        entry_price: position.entry_price,
        exit_price: exit_price,
        quantity: quantity,
        fees: DEFAULT_FEES,
        reason: reason
      )
    end
  end
end
