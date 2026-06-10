# frozen_string_literal: true

require "bigdecimal"

class TradingModel
  attr_reader :version, :length, :multiplier, :confidence, :execution_pf, :created_at, :activated_at, :deactivated_at
  attr_accessor :status

  def initialize(
    version:,
    length:,
    multiplier:,
    confidence:,
    execution_pf:,
    status: :candidate,
    created_at: nil,
    activated_at: nil,
    deactivated_at: nil
  )
    @version = version
    @length = length.to_i
    @multiplier = BigDecimal(multiplier.to_s)
    @confidence = BigDecimal(confidence.to_s)
    @execution_pf = BigDecimal(execution_pf.to_s)
    @status = status.to_sym
    @created_at = created_at || Time.now
    @activated_at = activated_at
    @deactivated_at = deactivated_at
  end

  def shadow!
    @status = :shadow
  end

  def approve!
    @status = :approved
  end

  def activate!
    @status = :active
    @activated_at = Time.now
  end

  def deactivate!
    @status = :deactivated
    @deactivated_at = Time.now
  end

  def rollback!
    @status = :rolled_back
    @deactivated_at = Time.now
  end

  def active?
    @status == :active
  end

  def shadow?
    @status == :shadow
  end
end
