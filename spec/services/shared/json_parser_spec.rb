# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shared::JsonParser do
  it "dumps and loads json" do
    payload = { a: 1 }

    json = described_class.dump(payload)

    expect(described_class.load(json)).to eq(
      "a" => 1
    )
  end
end
