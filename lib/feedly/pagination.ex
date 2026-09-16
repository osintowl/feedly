defmodule Feedly.Pagination do
  @moduledoc """
  Helpers for handling pagination with continuation tokens.
  """

  @type page_opts :: [
          count: pos_integer(),
          continuation: String.t() | nil,
          newer_than: DateTime.t() | integer() | nil,
          older_than: DateTime.t() | integer() | nil
        ]

  @type paginated_response :: %{
          items: list(),
          continuation: String.t() | nil,
          id: String.t() | nil,
          updated: integer() | nil
        }

  @doc """
  Builds query parameters for a paginated request.

  ## Options

    * `:count` - Number of items to return (1-100, default: 20)
    * `:continuation` - Continuation token from previous response
    * `:newer_than` - Only return items newer than this timestamp (DateTime or epoch ms)
    * `:older_than` - Only return items older than this timestamp (DateTime or epoch ms)

  """
  @spec build_params(page_opts()) :: map()
  def build_params(opts) do
    params = %{}

    params =
      if count = opts[:count] do
        Map.put(params, :count, min(count, 100))
      else
        params
      end

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

    params
  end

  @doc """
  Creates a stream that automatically fetches all pages.

  ## Examples

      Feedly.Pagination.stream(client, fn client, params ->
        Feedly.API.Streams.get_contents(client, stream_id, params)
      end)
      |> Stream.take(1000)
      |> Enum.to_list()

  """
  @spec stream(
          term(),
          (term(), map() -> {:ok, paginated_response()} | {:error, term()}),
          page_opts()
        ) ::
          Enumerable.t()
  def stream(client, fetch_fn, opts \\ []) do
    Stream.resource(
      fn -> {client, nil, opts} end,
      fn
        :done ->
          {:halt, :done}

        {client, continuation, opts} ->
          params =
            opts
            |> Keyword.put(:continuation, continuation)
            |> build_params()

          case fetch_fn.(client, params) do
            {:ok, %{items: items, continuation: next_continuation}} when is_list(items) ->
              if next_continuation && length(items) > 0 do
                {items, {client, next_continuation, opts}}
              else
                {items, :done}
              end

            {:ok, %{items: items}} when is_list(items) ->
              {items, :done}

            {:error, _reason} ->
              {:halt, :done}

            _ ->
              {:halt, :done}
          end
      end,
      fn _ -> :ok end
    )
    |> Stream.flat_map(& &1)
  end

  @doc """
  Extracts pagination info from a response.
  """
  @spec extract_pagination(map()) :: paginated_response()
  def extract_pagination(response) when is_map(response) do
    %{
      items: Map.get(response, "items", []),
      continuation: Map.get(response, "continuation"),
      id: Map.get(response, "id"),
      updated: Map.get(response, "updated")
    }
  end

  defp to_epoch_ms(%DateTime{} = dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp to_epoch_ms(epoch) when is_integer(epoch), do: epoch
end
