# frozen_string_literal: true

require "securerandom"

module Ha
  class LeaderElection
    attr_reader :node_id, :redis, :lock_key, :lease_ttl_seconds

    def initialize(redis: nil, lock_key: "trading_leader_lock", lease_ttl_seconds: 10)
      @node_id = SecureRandom.uuid
      @redis = redis
      @lock_key = lock_key
      @lease_ttl_seconds = lease_ttl_seconds
      @is_leader = false
    end

    def acquire!
      if redis.nil?
        @is_leader = true
        return true
      end

      res = redis.set(lock_key, node_id, nx: true, ex: lease_ttl_seconds)
      @is_leader = !!res
    rescue StandardError
      @is_leader = false
    end

    def active?
      if redis.nil?
        return @is_leader
      end

      current_holder = redis.get(lock_key)
      @is_leader = (current_holder == node_id)
    rescue StandardError
      @is_leader = false
    end

    def renew!
      return false unless @is_leader
      if redis.nil?
        return true
      end

      script = <<~LUA
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("expire", KEYS[1], ARGV[2])
        else
          return 0
        end
      LUA

      res = redis.eval(script, keys: [ lock_key ], argv: [ node_id, lease_ttl_seconds ])
      @is_leader = (res == 1)
    rescue StandardError
      @is_leader = false
    end

    def release!
      return false unless @is_leader
      if redis.nil?
        @is_leader = false
        return true
      end

      script = <<~LUA
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
        else
          return 0
        end
      LUA

      res = redis.eval(script, keys: [ lock_key ], argv: [ node_id ])
      @is_leader = false
      res == 1
    rescue StandardError
      @is_leader = false
    end
  end
end
