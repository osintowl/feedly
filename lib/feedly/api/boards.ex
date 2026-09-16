defmodule Feedly.API.Boards do
  @moduledoc """
  API for managing team boards (tags).
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the list of team board streamIds.

  ## Examples

      {:ok, boards} = Feedly.API.Boards.list(client)

  """
  @spec list(Config.t()) :: {:ok, list(map())} | {:error, term()}
  def list(%Config{} = config) do
    Client.get(config, "/tags")
  end

  @doc """
  Adds articles to a board.

  ## Examples

      {:ok, _} = Feedly.API.Boards.add_articles(client, "board_id", ["entry_id_1", "entry_id_2"])

  """
  @spec add_articles(Config.t(), String.t(), list(String.t())) :: {:ok, term()} | {:error, term()}
  def add_articles(%Config{} = config, tag_id, entry_ids) when is_list(entry_ids) do
    body = %{entryIds: entry_ids}
    Client.put(config, "/tags/#{URI.encode_www_form(tag_id)}/entries", body)
  end

  @doc """
  Removes an article from a board.

  ## Examples

      {:ok, _} = Feedly.API.Boards.delete_article(client, "board_id", "entry_id")

  """
  @spec delete_article(Config.t(), String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def delete_article(%Config{} = config, tag_id, entry_id) do
    Client.delete(
      config,
      "/tags/#{URI.encode_www_form(tag_id)}/entries/#{URI.encode_www_form(entry_id)}"
    )
  end
end
