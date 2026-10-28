defmodule Feedly.API.Folders do
  @moduledoc """
  API for team folders.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets all team folders with their associated feeds.

  ## Options

    * `:format` - Response format: "json" (default) or "csv"

  ## Examples

      {:ok, folders, _rate} = Feedly.API.Folders.list(client)

  """
  @spec list(Config.t(), keyword()) ::
          {:ok, list(map()), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def list(%Config{} = config, opts \\ []) do
    params = %{}

    params =
      if format = opts[:format] do
        Map.put(params, :format, format)
      else
        params
      end

    Client.get(config, "/enterprise/collections", params: params)
  end
end
