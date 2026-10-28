defmodule Feedly.API.Search do
  @moduledoc """
  API for searching articles in Feedly.
  """

  alias Feedly.{Client, Config, Pagination}
  alias Feedly.Schemas.Article

  @doc """
  Searches for articles based on query layers.

  ## Query Structure

  The query is a map with the following structure:

      %{
        layers: [
          %{type: "matches", parts: [%{text: "ransomware"}], salience: "about"},
          %{type: "language", languages: ["en"]}
        ],
        source: %{
          items: [
            %{type: "publicationBucket", id: "byf:cybersecurity-bundle", tier: "tier1"}
          ]
        }
      }

  ## Options

    * `:count` - Number of results (1-100, default: 10)
    * `:continuation` - Continuation token for pagination
    * `:newer_than` - Only return articles newer than this timestamp
    * `:older_than` - Only return articles older than this timestamp
    * `:unread_only` - Only return unread articles (default: false)
    * `:include_ai_actions` - Include AI actions (default: true)

  ## Examples

      query = %{
        layers: [
          %{type: "matches", parts: [%{text: "kubernetes"}], salience: "about"}
        ]
      }

      {:ok, results, _rate} = Feedly.API.Search.query(client, query, count: 50)

  """
  @spec query(Config.t(), map(), keyword()) ::
          {:ok, %{items: list(Article.t()), continuation: String.t() | nil},
           Feedly.RateLimiter.rate_info() | nil}
          | {:error, Feedly.Error.t()}
  def query(%Config{} = config, query_body, opts \\ []) do
    params = %{
      count: Keyword.get(opts, :count, 10),
      includeAiActions: Keyword.get(opts, :include_ai_actions, true)
    }

    params =
      if continuation = opts[:continuation] do
        Map.put(params, :continuation, continuation)
      else
        params
      end

    params =
      if newer_than = opts[:newer_than] do
        Map.put(params, :newerThan, to_epoch_ms(newer_than))
      else
        params
      end

    params =
      if older_than = opts[:older_than] do
        Map.put(params, :olderThan, to_epoch_ms(older_than))
      else
        params
      end

    params =
      if opts[:unread_only] do
        Map.put(params, :unreadOnly, true)
      else
        params
      end

    with {:ok, response, rate_info} <-
           Client.post(config, "/search/contents", query_body, params: params) do
      items =
        response
        |> Map.get("items", [])
        |> Enum.map(&Article.from_api/1)

      {:ok,
       %{
         items: items,
         continuation: Map.get(response, "continuation"),
         id: Map.get(response, "id"),
         updated: Map.get(response, "updated")
       }, rate_info}
    end
  end

  @doc """
  Returns a stream that automatically fetches all search result pages.

  ## Examples

      query = %{layers: [...]}
      
      Feedly.API.Search.stream_all(client, query)
      |> Stream.take(500)
      |> Enum.to_list()

  """
  @spec stream_all(Config.t(), map(), keyword()) :: Enumerable.t()
  def stream_all(%Config{} = config, query_body, opts \\ []) do
    Pagination.stream(
      config,
      fn config, params ->
        opts
        |> Keyword.merge(Enum.to_list(params))
        |> then(&query(config, query_body, &1))
      end,
      opts
    )
  end

  defp to_epoch_ms(%DateTime{} = dt), do: DateTime.to_unix(dt, :millisecond)
  defp to_epoch_ms(epoch) when is_integer(epoch), do: epoch
end
