# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shared::Retryable do
  let(:dummy) do
    Class.new do
      include Shared::Retryable
    end.new
  end

  it "retries and succeeds" do
    attempts = 0

    result = dummy.with_retry(attempts: 3) do
      attempts += 1

      raise StandardError if attempts < 2

      :success
    end

    expect(result).to eq(:success)
    expect(attempts).to eq(2)
  end
end