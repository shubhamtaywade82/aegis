# frozen_string_literal: true

require "rails_helper"

RSpec.describe DashboardController, type: :request do
  describe "GET /dashboard" do
    context "without symbol param" do
      it "returns a successful 200 response" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end

      it "defaults to BTCUSDT symbol" do
        get "/dashboard"
        expect(assigns(:symbol)).to eq("BTCUSDT")
      end

      it "renders the dashboard index template" do
        get "/dashboard"
        expect(response).to render_template(:index)
      end

      it "renders turbo-frame wrapper" do
        get "/dashboard"
        expect(response.body).to include('id="dashboard-frame"')
      end

      it "renders all four dashboard cards" do
        get "/dashboard"
        expect(response.body).to include("Price")
        expect(response.body).to include("Supertrend")
        expect(response.body).to include("Positions")
        expect(response.body).to include("Account")
      end

      it "includes turbo_stream_from for the symbol channel" do
        get "/dashboard"
        expect(response.body).to include("turbo-cable-stream-source")
      end

      it "renders price card partial" do
        get "/dashboard"
        expect(response.body).to include('id="price-card-BTCUSDT"')
      end
    end

    context "with symbol param" do
      it "returns a successful 200 response" do
        get "/dashboard", params: { symbol: "ETHUSDT" }
        expect(response).to have_http_status(:ok)
      end

      it "uses the provided symbol" do
        get "/dashboard", params: { symbol: "ETHUSDT" }
        expect(assigns(:symbol)).to eq("ETHUSDT")
      end

      it "upcases the symbol" do
        get "/dashboard", params: { symbol: "ethusdt" }
        expect(assigns(:symbol)).to eq("ETHUSDT")
      end

      it "streams from the correct symbol channel" do
        get "/dashboard", params: { symbol: "SOLUSDT" }
        expect(response.body).to include("turbo-cable-stream-source")
      end

      it "renders price card with correct symbol" do
        get "/dashboard", params: { symbol: "XRPUSDT" }
        expect(response.body).to include('id="price-card-XRPUSDT"')
      end
    end

    context "with unsupported symbol" do
      it "still responds successfully (symbols are validated by the feed)" do
        get "/dashboard", params: { symbol: "NOTREAL" }
        expect(response).to have_http_status(:ok)
        expect(assigns(:symbol)).to eq("NOTREAL")
      end
    end

    context "@market_data instance variables" do
      it "loads latest_tick from MarketDataFeed" do
        allow(MarketDataFeed).to receive(:latest_tick).with("BTCUSDT").and_return(nil)
        get "/dashboard"
        expect(assigns(:latest_tick)).to be_nil
      end

      it "loads latest_kline from MarketDataFeed" do
        allow(MarketDataFeed).to receive(:latest_kline).with("BTCUSDT").and_return(nil)
        get "/dashboard"
        expect(assigns(:latest_kline)).to be_nil
      end

      it "sets positions to empty array" do
        get "/dashboard"
        expect(assigns(:positions)).to eq([])
      end

      it "sets account to empty hash" do
        get "/dashboard"
        expect(assigns(:account)).to eq({})
      end

      it "sets @supertrend to nil initially (Phase 3)" do
        get "/dashboard"
        expect(assigns(:supertrend)).to be_nil
      end
    end

    context "price partial rendering" do
      it "renders empty state when no tick data" do
        allow(MarketDataFeed).to receive(:latest_tick).with("BTCUSDT").and_return(nil)
        get "/dashboard"
        expect(response.body).to include("No price data available")
      end

      it "renders price when tick data present" do
        tick = {
          "c" => "97000.00",
          "o" => "96000.00",
          "h" => "98000.00",
          "l" => "95000.00",
          "P" => "1.04",
          "v" => "100.5",
          "q" => "9700000.00"
        }
        allow(MarketDataFeed).to receive(:latest_tick).with("BTCUSDT").and_return(tick)
        get "/dashboard"
        expect(response.body).to include("97,000")
        expect(response.body).to include("+1.04")
      end
    end

    context "supertrend partial rendering" do
      it "renders unavailable state when supertrend is nil" do
        get "/dashboard"
        expect(response.body).to include("Supertrend data unavailable")
      end
    end

    context "positions partial rendering" do
      it "renders empty state when no positions" do
        get "/dashboard"
        expect(response.body).to include("No open positions")
      end
    end

    context "symbol selector" do
      it "renders symbol dropdown with options" do
        get "/dashboard"
        expect(response.body).to include('id="symbol-select"')
        expect(response.body).to include("BTCUSDT")
        expect(response.body).to include("ETHUSDT")
      end

      it "renders stimulus data attribute for symbol-selector controller" do
        get "/dashboard"
        expect(response.body).to include('data-controller="symbol-selector"')
        expect(response.body).to include('data-action="change->symbol-selector#change"')
      end

      it "marks current symbol as selected in dropdown" do
        get "/dashboard", params: { symbol: "ETHUSDT" }
        expect(response.body).to include('value="ETHUSDT" selected')
      end
    end
  end
end
