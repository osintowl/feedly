defmodule Feedly.API.ThreatIntel.Cyberattacks do
  @moduledoc """
  API for the Cyberattacks Agent.
  """

  alias Feedly.{Client, Config}

  @doc """
  Queries the Cyberattacks Agent.

  ## Query Structure

  The query body should contain filters like:
  - `layers`: Filter layers (time period, victim country, industry, attack type, etc.)
  - `count`: Number of results
  - `continuation`: For pagination
  - `sort`: Sort configuration

  ## Examples

      query = %{
        layers: [
          %{
            filters: [
              %{field: "period", value: %{type: "Last30Days"}},
              %{field: "victimCountry", value: "US"}
            ]
          }
        ],
        count: 50
      }

      {:ok, results, _rate} = Feedly.API.ThreatIntel.Cyberattacks.query(client, query)

  """
  @spec query(Config.t(), map()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def query(%Config{} = config, query_body) do
    Client.post(config, "/dashboards/cyberattacks", query_body)
  end

  @doc """
  Gets statistics for cyberattacks based on query filters.

  ## Examples

      query = %{
        layers: [
          %{filters: [%{field: "period", value: %{type: "Last30Days"}}]}
        ]
      }

      {:ok, stats, _rate} = Feedly.API.ThreatIntel.Cyberattacks.statistics(client, query)

  """
  @spec statistics(Config.t(), map()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def statistics(%Config{} = config, query_body) do
    Client.post(config, "/dashboards/cyberattacks/statistics", query_body)
  end

  @doc """
  Gets details for a specific cyberattack.

  ## Examples

      {:ok, attack, _rate} = Feedly.API.ThreatIntel.Cyberattacks.get(client, "attack_id")

  """
  @spec get(Config.t(), String.t()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get(%Config{} = config, attack_id) do
    Client.get(config, "/dashboards/cyberattacks/#{Client.encode_path(attack_id)}")
  end
end
