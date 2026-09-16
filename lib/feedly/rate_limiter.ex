defmodule Feedly.RateLimiter do
  @moduledoc """
  Rate limiting information and backoff handling for Feedly API.
  """

  @type rate_info :: %{
          count: integer(),
          limit: integer(),
          reset_in: integer()
        }

  @doc """
  Extracts rate limit information from response headers.

  ## Examples

      iex> headers = %{"x-ratelimit-count" => "57", "x-ratelimit-limit" => "100000", "x-ratelimit-reset" => "23841"}
      iex> Feedly.RateLimiter.parse_headers(headers)
      %{count: 57, limit: 100000, reset_in: 23841}

  """
  @spec parse_headers(map()) :: rate_info() | nil
  def parse_headers(headers) do
    with count when not is_nil(count) <- get_header(headers, "x-ratelimit-count"),
         limit when not is_nil(limit) <- get_header(headers, "x-ratelimit-limit"),
         reset when not is_nil(reset) <- get_header(headers, "x-ratelimit-reset") do
      %{
        count: String.to_integer(count),
        limit: String.to_integer(limit),
        reset_in: String.to_integer(reset)
      }
    else
      _ -> nil
    end
  end

  @doc """
  Calculates backoff delay based on rate limit status.

  Returns the number of milliseconds to wait before the next request.
  If rate limit is approaching (>90%), suggests waiting until reset.
  """
  @spec backoff_delay(rate_info()) :: integer()
  def backoff_delay(%{count: count, limit: limit, reset_in: reset_in}) do
    usage_percent = count / limit * 100

    cond do
      usage_percent >= 99.0 ->
        # Almost at limit, wait until reset
        reset_in * 1000

      usage_percent >= 90.0 ->
        # Approaching limit, slow down significantly
        min(reset_in * 1000, 60_000)

      true ->
        # Normal operation
        0
    end
  end

  @doc """
  Checks if we should wait before making the next request.
  """
  @spec should_wait?(rate_info()) :: boolean()
  def should_wait?(rate_info) do
    backoff_delay(rate_info) > 0
  end

  defp get_header(headers, key) do
    headers[key] || headers[String.downcase(key)]
  end
end
