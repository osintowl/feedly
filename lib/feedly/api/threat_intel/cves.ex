defmodule Feedly.API.ThreatIntel.CVEs do
  @moduledoc """
  API for CVE (vulnerability) threat intelligence.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets trending CVEs from the Threat Landscape Dashboard.

  ## Options

    * `:count` - Number of results (default: 20)
    * `:period` - Time period: "day", "week", "month" (default: "week")

  ## Examples

      {:ok, cves, _rate} = Feedly.API.ThreatIntel.CVEs.trending(client)

  """
  @spec trending(Config.t(), keyword()) ::
          {:ok, list(map()), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def trending(%Config{} = config, opts \\ []) do
    params = %{
      count: Keyword.get(opts, :count, 20)
    }

    params =
      if period = opts[:period] do
        Map.put(params, :period, period)
      else
        params
      end

    Client.get(config, "/trends/cves", params: params)
  end

  @doc """
  Gets detailed metadata for a CVE.

  ## Examples

      {:ok, cve, _rate} = Feedly.API.ThreatIntel.CVEs.get(client, "CVE-2024-1234")

  """
  @spec get(Config.t(), String.t(), keyword()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get(%Config{} = config, cve_id, opts \\ []) do
    entity_id = build_entity_id(cve_id)

    params = %{}

    params =
      if opts[:include_articles] do
        Map.put(params, :includeArticles, true)
      else
        params
      end

    Client.get(config, "/entities/#{Client.encode_path(entity_id)}", params: params)
  end

  @doc """
  Gets metadata for multiple CVEs.

  ## Examples

      {:ok, cves, _rate} = Feedly.API.ThreatIntel.CVEs.get_multiple(client, ["CVE-2024-1234", "CVE-2024-5678"])

  """
  @spec get_multiple(Config.t(), list(String.t())) ::
          {:ok, list(map()), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get_multiple(%Config{} = config, cve_ids) when is_list(cve_ids) do
    entity_ids = Enum.map(cve_ids, &build_entity_id/1)
    Client.post(config, "/entities/.mget", entity_ids)
  end

  @doc """
  Gets the timeline of events for a CVE.

  ## Examples

      {:ok, timeline, _rate} = Feedly.API.ThreatIntel.CVEs.timeline(client, "CVE-2024-1234")

  """
  @spec timeline(Config.t(), String.t()) ::
          {:ok, list(map()), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def timeline(%Config{} = config, cve_id) do
    entity_id = build_entity_id(cve_id)
    Client.get(config, "/entities/#{Client.encode_path(entity_id)}/timeline")
  end

  @doc """
  Queries the Vulnerability Agent with custom filters.

  ## Query Structure

  The query body should contain:
  - `layers`: Filter layers (e.g., period, cvssScore, exploited, etc.)
  - `count`: Number of results
  - `continuation`: For pagination
  - `sort`: Sort configuration

  ## Examples

      query = %{
        layers: [
          %{
            filters: [
              %{
                field: "cvssScore",
                value: %{gte: 9.0}
              }
            ]
          }
        ],
        count: 50
      }

      {:ok, results, _rate} = Feedly.API.ThreatIntel.CVEs.query_agent(client, query)

  """
  @spec query_agent(Config.t(), map()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def query_agent(%Config{} = config, query_body) do
    Client.post(config, "/dashboards/vulnerability", query_body)
  end

  defp build_entity_id("vulnerability/m/entity/" <> _ = id), do: id
  defp build_entity_id("CVE-" <> _ = cve_id), do: "vulnerability/m/entity/#{cve_id}"
  defp build_entity_id(cve_id), do: "vulnerability/m/entity/CVE-#{cve_id}"
end
