# frozen_string_literal: true

module Ha
  class FailoverCoordinator
    attr_reader :leader_election, :reconciliation_service, :execution_engine, :status

    def initialize(leader_election:, reconciliation_service:, execution_engine:)
      @leader_election = leader_election
      @reconciliation_service = reconciliation_service
      @execution_engine = execution_engine
      @status = :standby
    end

    def run_cycle!
      if leader_election.acquire! || leader_election.active?
        if @status == :standby
          @status = :reconciling
          if reconciliation_service.reconcile!
            @status = :active
          else
            @status = :paused_mismatch
          end
        elsif @status == :active
          unless leader_election.renew!
            @status = :standby
          end
        end
      else
        @status = :standby
      end

      @status
    end
  end
end
