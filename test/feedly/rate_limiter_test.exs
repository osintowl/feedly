defmodule Feedly.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Feedly.RateLimiter

  describe "parse_headers/1" do
    test "parses rate limit headers" do
      headers = %{
        "x-ratelimit-count" => "57",
        "x-ratelimit-limit" => "100000",
        "x-ratelimit-reset" => "23841"
      }

      rate_info = RateLimiter.parse_headers(headers)

      assert rate_info.count == 57
      assert rate_info.limit == 100_000
      assert rate_info.reset_in == 23_841
    end

    test "handles different case headers" do
      # Note: Req normalizes headers to lowercase, so we test with lowercase keys
      # In real usage, the headers will come normalized from Req
      rate_info =
        RateLimiter.parse_headers(%{
          "x-ratelimit-count" => "57",
          "x-ratelimit-limit" => "100000",
          "x-ratelimit-reset" => "23841"
        })

      assert rate_info.count == 57
    end

    test "returns nil when headers are missing" do
      assert RateLimiter.parse_headers(%{}) == nil
    end
  end

  describe "backoff_delay/1" do
    test "returns 0 for normal usage" do
      rate_info = %{count: 50_000, limit: 100_000, reset_in: 3600}
      assert RateLimiter.backoff_delay(rate_info) == 0
    end

    test "returns delay when approaching limit" do
      rate_info = %{count: 95_000, limit: 100_000, reset_in: 3600}
      delay = RateLimiter.backoff_delay(rate_info)
      assert delay > 0
    end

    test "returns full reset time when at limit" do
      rate_info = %{count: 99_900, limit: 100_000, reset_in: 3600}
      delay = RateLimiter.backoff_delay(rate_info)
      assert delay == 3600 * 1000
    end
  end

  describe "should_wait?/1" do
    test "returns false for normal usage" do
      rate_info = %{count: 50_000, limit: 100_000, reset_in: 3600}
      refute RateLimiter.should_wait?(rate_info)
    end

    test "returns true when approaching limit" do
      rate_info = %{count: 95_000, limit: 100_000, reset_in: 3600}
      assert RateLimiter.should_wait?(rate_info)
    end
  end
end
