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

      {:ok, result, _rate} = Feedly.API.ThreatIntel.IoCs.collect(client,
        stream_id: "enterprise/feedly/category/...",
        count: 50
      )

  """
  @spec collect(Config.t(), keyword()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def collect(%Config{} = config, opts) do
    stream_id = Keyword.fetch!(opts, :stream_id)

    params =
      opts
      |> Keyword.delete(:stream_id)
      |> Pagination.build_params()
      |> Map.put(:streamId, stream_id)

    Client.get(config, "/streams/contents", params: params)
  end

  @doc """
  Gets metadata for a specific IoC.

  ## Options

    * `:include_articles` - Include articles mentioning this IoC (default: false)

  ## Examples

      {:ok, ioc, _rate} = Feedly.API.ThreatIntel.IoCs.get(client, "ioc_id")

  """
  @spec get(Config.t(), String.t(), keyword()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get(%Config{} = config, ioc_id, opts \\ []) do
    params = %{}

    params =
      if opts[:include_articles] do
        Map.put(params, :includeArticles, true)
      else
        params
      end

    Client.get(config, "/entities/#{Client.encode_path(ioc_id)}", params: params)
  end

  @doc """
  Extracts IoCs from articles in a response.

  Returns a flat list of all IoCs with their types and contexts.
  """
  @spec extract_from_articles(list(map() | Feedly.Schemas.Article.t())) :: list(map())
  def extract_from_articles(articles) when is_list(articles) do
    Enum.flat_map(articles, &extract_from_article/1)
  end

  defp extract_from_article(%Feedly.Schemas.Article{} = article) do
    mentions(article.indicators_of_compromise, article.id)
  end

  defp extract_from_article(article) when is_map(article) do
    mentions(article["indicatorsOfCompromise"], article["id"])
  end

  defp mentions(%{"mentions" => mentions}, article_id) when is_list(mentions) do
    Enum.map(mentions, &Map.put(&1, "article_id", article_id))
  end

  defp mentions(_, _), do: []
end
