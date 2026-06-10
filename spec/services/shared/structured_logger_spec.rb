# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shared::StructuredLogger do
  let(:logger) { instance_double(Logger) }

  subject(:structured_logger) do
    described_class.new(logger: logger)
  end

  it "logs structured json" do
    expect(logger).to receive(:info)

    structured_logger.info(
      event: "trade.entered",
      message: "Entry executed",
      symbol: "SOLUSDT"
    )
  end
end