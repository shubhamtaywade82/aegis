# frozen_string_literal: true

class SoakReport
  attr_reader :duration_hours,
              :uptime_percentage,
              :orders_processed,
              :trades_processed,
              :duplicate_orders,
              :orphan_positions,
              :reconciliation_failures,
              :event_loss,
              :risk_failures,
              :peak_memory_mb,
              :peak_cpu_percent,
              :kill_switch_passed,
              :recovery_tests_passed,
              :certified

  def initialize(
    duration_hours:,
    uptime_percentage:,
    orders_processed:,
    trades_processed:,
    duplicate_orders:,
    orphan_positions:,
    reconciliation_failures:,
    event_loss:,
    risk_failures:,
    peak_memory_mb:,
    peak_cpu_percent:,
    kill_switch_passed:,
    recovery_tests_passed:
  )
    @duration_hours = duration_hours.to_f
    @uptime_percentage = uptime_percentage.to_f
    @orders_processed = orders_processed.to_i
    @trades_processed = trades_processed.to_i
    @duplicate_orders = duplicate_orders.to_i
    @orphan_positions = orphan_positions.to_i
    @reconciliation_failures = reconciliation_failures.to_i
    @event_loss = event_loss.to_i
    @risk_failures = risk_failures.to_i
    @peak_memory_mb = peak_memory_mb.to_f
    @peak_cpu_percent = peak_cpu_percent.to_f
    @kill_switch_passed = !!kill_switch_passed
    @recovery_tests_passed = !!recovery_tests_passed

    @certified = evaluate_certification
    freeze
  end

  def certified?
    certified
  end

  private

  def evaluate_certification
    uptime_percentage >= 99.0 &&
      duplicate_orders.zero? &&
      orphan_positions.zero? &&
      reconciliation_failures.zero? &&
      event_loss.zero? &&
      risk_failures.zero? &&
      kill_switch_passed &&
      recovery_tests_passed
  end
end
