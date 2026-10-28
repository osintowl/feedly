defmodule Feedly.API.AIFeeds do
  @moduledoc """
  API for AI Feeds (alerts).
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the list of AI Feeds from the enterprise team.

  Returns both user alerts and enterprise alerts.

  ## Examples

      {:ok, %{"userAlerts" => user_alerts, "enterpriseAlerts" => enterprise_alerts}, _rate} =
        Feedly.API.AIFeeds.list(client)

  """
  @spec list(Config.t()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def list(%Config{} = config) do
    Client.get(config, "/alerts")
  end
end
