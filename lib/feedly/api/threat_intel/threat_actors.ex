defmodule Feedly.API.ThreatIntel.ThreatActors do
  @moduledoc """
  API for threat actor intelligence.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets trending threat actors.

  ## Options

    * `:count` - Number of results (default: 20)
    * `:period` - Time period: "day", "week", "month" (default: "week")

  ## Examples

      {:ok, actors} = Feedly.API.ThreatIntel.ThreatActors.trending(client)

  """
  @spec trending(Config.t(), keyword()) :: {:ok, list(map())} | {:error, term()}
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

    Client.get(config, "/trends/attackers", params: params)
  end

  @doc """
  Gets detailed metadata for a threat actor.

  ## Examples

      {:ok, actor} = Feedly.API.ThreatIntel.ThreatActors.get(client, "gz:ta:68391641-859f-4a9a-9a1e-3e5cf71ec376")

  """
  @spec get(Config.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(%Config{} = config, actor_id, opts \\ []) do
    entity_id = build_entity_id(actor_id)

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
  Gets relationships for a threat actor (IoCs, TTPs, malware, etc.).

  ## Examples

      {:ok, relationships} = Feedly.API.ThreatIntel.ThreatActors.relationships(client, "gz:ta:...")

  """
  @spec relationships(Config.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def relationships(%Config{} = config, actor_id) do
    entity_id = build_entity_id(actor_id)
    Client.get(config, "/entities/#{Client.encode_path(entity_id)}/relationships")
  end

  defp build_entity_id("nlp/f/entity/gz:ta:" <> _ = id), do: id
  defp build_entity_id("gz:ta:" <> _ = id), do: "nlp/f/entity/#{id}"
  defp build_entity_id(id), do: "nlp/f/entity/gz:ta:#{id}"
end
