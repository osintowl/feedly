defmodule Feedly.API.Streams do
  @moduledoc """
  API for collecting articles from Feedly streams (AI Feeds, Folders, Boards).
  """

  alias Feedly.{Client, Config, Pagination}
  alias Feedly.Schemas.Article

  @doc """
  Collects articles from a stream ID.

  ## Options

    * `:count` - Number of articles to return (1-100, default: 20)
    * `:continuation` - Continuation token for pagination
    * `:newer_than` - Only return articles newer than this timestamp
    * `:older_than` - Only return articles older than this timestamp
    * `:include_ai_actions` - Include AI actions in response (default: true)
    * `:similar` - Include numRelatedEntries (default: true)

  ## Examples

      {:ok, result} = Feedly.API.Streams.get_contents(client, 
        stream_id: "enterprise/feedly/category/...",
        count: 50
      )

  """
  @spec get_contents(Config.t(), keyword()) ::
          {:ok, %{items: list(Article.t()), continuation: String.t() | nil}} | {:error, term()}
  def get_contents(%Config{} = config, opts) do
    stream_id = Keyword.fetch!(opts, :stream_id)

    params =
      opts
      |> Keyword.delete(:stream_id)
      |> Pagination.build_params()
      |> Map.put(:streamId, URI.encode_www_form(stream_id))
      |> Map.put(:includeAiActions, Keyword.get(opts, :include_ai_actions, true))
      |> Map.put(:similar, Keyword.get(opts, :similar, true))

    with {:ok, response} <- Client.get(config, "/streams/contents", params: params) do
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
       }}
    end
  end

  @doc """
  Returns a stream that automatically fetches all pages of articles.

  ## Examples

      Feedly.API.Streams.stream_all(client, stream_id: "...")
      |> Stream.take(1000)
      |> Enum.to_list()

  """
  @spec stream_all(Config.t(), keyword()) :: Enumerable.t()
  def stream_all(%Config{} = config, opts) do
    stream_id = Keyword.fetch!(opts, :stream_id)

    Pagination.stream(
      config,
      fn config, params ->
        opts
        |> Keyword.merge(Enum.to_list(params))
        |> Keyword.put(:stream_id, stream_id)
        |> then(&get_contents(config, &1))
      end,
      opts
    )
  end
end
