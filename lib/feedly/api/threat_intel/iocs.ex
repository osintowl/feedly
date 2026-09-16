defmodule Feedly.API.ThreatIntel.IoCs do
  @moduledoc """
  API for Indicators of Compromise (IoCs).
  """

  alias Feedly.{Client, Config, Pagination}

  @doc """
  Collects IoCs with rich context from a stream.

  ## Options

    * `:stream_id` - Required stream ID to collect from
    * `:count` - Number of articles to return (1-100, default: 20)
    * `:continuation` - Continuation token for pagination
    * `:newer_than` - Only return articles newer than this timestamp
    * `:older_than` - Only return articles older than this timestamp

  ## Examples

      {:ok, result} = Feedly.API.ThreatIntel.IoCs.collect(client,
        stream_id: "enterprise/feedly/category/...",
        count: 50
      )

  """
  @spec collect(Config.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def collect(%Config{} = config, opts) do
    stream_id = Keyword.fetch!(opts, :stream_id)

    params =
      opts
      |> Keyword.delete(:stream_id)
      |> Pagination.build_params()
      |> Map.put(:streamId, URI.encode_www_form(stream_id))

    Client.get(config, "/streams/contents", params: params)
  end

  @doc """
  Gets metadata for a specific IoC.

  ## Options

    * `:include_articles` - Include articles mentioning this IoC (default: false)

  ## Examples

      {:ok, ioc} = Feedly.API.ThreatIntel.IoCs.get(client, "ioc_id")

  """
  @spec get(Config.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(%Config{} = config, ioc_id, opts \\ []) do
    params = %{}

    params =
      if opts[:include_articles] do
        Map.put(params, :includeArticles, true)
      else
        params
      end

    Client.get(config, "/entities/#{URI.encode_www_form(ioc_id)}", params: params)
  end

  @doc """
  Extracts IoCs from articles in a response.

  Returns a flat list of all IoCs with their types and contexts.
  """
  @spec extract_from_articles(list(map())) :: list(map())
  def extract_from_articles(articles) when is_list(articles) do
    articles
    |> Enum.flat_map(fn article ->
      case article["indicatorsOfCompromise"] do
        %{"mentions" => mentions} when is_list(mentions) ->
          Enum.map(mentions, fn ioc ->
            Map.put(ioc, "article_id", article["id"])
          end)

        _ ->
          []
      end
    end)
  end
end
