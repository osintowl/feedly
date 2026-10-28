defmodule Feedly.API.Profile do
  @moduledoc """
  API for user profile information.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the authenticated user's profile.

  ## Examples

      {:ok, profile, _rate} = Feedly.API.Profile.get(client)

  """
  @spec get(Config.t()) ::
          {:ok, map(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get(%Config{} = config) do
    Client.get(config, "/profile")
  end
end
