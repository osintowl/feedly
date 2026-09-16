defmodule Feedly.API.Profile do
  @moduledoc """
  API for user profile information.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the authenticated user's profile.

  ## Examples

      {:ok, profile} = Feedly.API.Profile.get(client)

  """
  @spec get(Config.t()) :: {:ok, map()} | {:error, term()}
  def get(%Config{} = config) do
    Client.get(config, "/profile")
  end
end
