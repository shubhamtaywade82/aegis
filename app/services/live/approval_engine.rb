# frozen_string_literal: true

module Live
  class ApprovalEngine
    attr_reader :pending_approvals

    def initialize
      @pending_approvals = {}
    end

    def request_approval(order_request)
      id = order_request.client_order_id
      @pending_approvals[id] = {
        order: order_request,
        status: :pending,
        requested_at: Time.now
      }
      id
    end

    def approve!(id)
      return false unless @pending_approvals.key?(id)
      @pending_approvals[id][:status] = :approved
      true
    end

    def reject!(id)
      return false unless @pending_approvals.key?(id)
      @pending_approvals[id][:status] = :rejected
      true
    end

    def status_of(id)
      @pending_approvals.dig(id, :status)
    end
  end
end
