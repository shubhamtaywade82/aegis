# frozen_string_literal: true

class RiskDecision
  attr_reader :approved, :reasons, :severity

  def initialize(approved:, reasons: [], severity: :none)
    @approved = approved
    @reasons = reasons.freeze
    @severity = severity.to_sym

    freeze
  end

  def approved?
    approved
  end
end
