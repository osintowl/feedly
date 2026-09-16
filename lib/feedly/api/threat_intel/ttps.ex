defmodule Feedly.API.ThreatIntel.TTPs do
  @moduledoc """
  API for MITRE ATT&CK Tactics, Techniques, and Procedures (TTPs).
  """

  alias Feedly.{Client, Config}

  @doc """
  Lists TTPs from the TTP Agent.

  ## Examples

      {:ok, ttps} = Feedly.API.ThreatIntel.TTPs.list(client)

  """
  @spec list(Config.t()) :: {:ok, list(map())} | {:error, term()}
  def list(%Config{} = config) do
    Client.get(config, "/dashboards/ttps")
  end

  @doc """
  Collects procedures and articles from the TTP Agent.

  ## Options

    * `:ttp_id` - Required TTP entity ID
    * `:count` - Number of results (default: 20)
    * `:continuation` - Continuation token for pagination

  ## Examples

      {:ok, procedures} = Feedly.API.ThreatIntel.TTPs.procedures(client,
        ttp_id: "nlp/f/entity/gz:mi:attack-pattern-..."
      )

  """
  @spec procedures(Config.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def procedures(%Config{} = config, opts) do
    ttp_id = Keyword.fetch!(opts, :ttp_id)

    params = %{
      ttpId: ttp_id,
      count: Keyword.get(opts, :count, 20)
    }

    params =
      if continuation = opts[:continuation] do
        Map.put(params, :continuation, continuation)
      else
        params
      end

    Client.get(config, "/dashboards/ttps/procedures", params: params)
  end
end
