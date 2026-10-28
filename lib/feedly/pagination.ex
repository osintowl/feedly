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

  A failed page raises `Feedly.Error` instead of ending the stream early.

  ## Examples

      Feedly.API.Streams.stream_all(client, stream_id: stream_id)
      |> Stream.take(1000)
      |> Enum.to_list()

  """
  @spec stream(
          term(),
          (term(), map() ->
             {:ok, paginated_response(), Feedly.RateLimiter.rate_info() | nil}
             | {:error, term()}),
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
            {:ok, %{items: items, continuation: next_continuation}, _rate}
            when is_list(items) ->
              next_page(items, next_continuation, client, opts)

            {:ok, %{items: items, continuation: next_continuation}} when is_list(items) ->
              next_page(items, next_continuation, client, opts)

            {:ok, %{items: items}, _rate} when is_list(items) ->
              {items, :done}

            {:ok, %{items: items}} when is_list(items) ->
              {items, :done}

            {:error, %Feedly.Error{} = error} ->
              raise error

            {:error, reason} ->
              raise Feedly.Error.new(:unknown, "pagination failed: #{inspect(reason)}")

            other ->
              raise Feedly.Error.new(:unknown, "pagination failed: #{inspect(other)}")
          end
      end,
      fn _ -> :ok end
    )
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

  defp next_page(items, next_continuation, client, opts) do
    if is_binary(next_continuation) and next_continuation != "" and items != [] do
      {items, {client, next_continuation, opts}}
    else
      {items, :done}
    end
  end

  defp to_epoch_ms(%DateTime{} = dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp to_epoch_ms(epoch) when is_integer(epoch), do: epoch
end
