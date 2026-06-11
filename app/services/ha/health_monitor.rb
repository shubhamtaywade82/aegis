# frozen_string_literal: true

module Ha
  class HealthMonitor
    def initialize(leader_election: nil, reconciliation_service: nil)
      @leader_election = leader_election
      @reconciliation_service = reconciliation_service
    end

    def liveness_check
      true
    end

    def readiness_check
      return false if @leader_election && @leader_election.active? && @reconciliation_service && !@reconciliation_service.reconcile!

      true
    end
  end
end
