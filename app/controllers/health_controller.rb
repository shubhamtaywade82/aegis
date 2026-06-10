# frozen_string_literal: true

class HealthController < ActionController::API
  def show
    render json: {
      status: "ok",
      timestamp: Time.current
    }
  end

  def ready
    checks = {
      database: database?,
      redis: redis?,
      sidekiq: sidekiq?
    }

    if checks.values.all?
      render json: {
        status: "ready",
        checks: checks
      }
    else
      render json: {
        status: "not_ready",
        checks: checks
      }, status: :service_unavailable
    end
  end

  private

  def database?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis?
    Redis.new(url: ENV.fetch("REDIS_URL")).ping == "PONG"
  rescue StandardError
    false
  end

  def sidekiq?
    Redis.new(url: ENV.fetch("REDIS_URL")).exists?("processes")
  rescue StandardError
    false
  end
end
