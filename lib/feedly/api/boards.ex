defmodule Feedly.API.Boards do
  @moduledoc """
  API for managing team boards (tags).
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the team boards for the authenticated enterprise account.

  Each board map includes `"id"` (the stream id), `"label"`, and optionally
  `"description"`.

  ## Examples

      {:ok, boards} = Feedly.API.Boards.list(client)

  """
  @spec list(Config.t()) :: {:ok, list(map())} | {:error, term()}
  def list(%Config{} = config) do
    Client.get(config, "/enterprise/tags")
  end

  @doc """
  Adds articles to a board.

  ## Examples

      {:ok, _} = Feedly.API.Boards.add_articles(client, "board_id", ["entry_id_1", "entry_id_2"])

  """
  @spec add_articles(Config.t(), String.t(), list(String.t())) :: {:ok, term()} | {:error, term()}
  def add_articles(%Config{} = config, tag_id, entry_ids) when is_list(entry_ids) do
    body =
      case entry_ids do
        [entry_id] -> %{entryId: entry_id}
        ids -> %{entryIds: ids}
      end

    Client.put(config, "/tags/#{Client.encode_path(tag_id)}", body)
  end

  @doc """
  Removes an article from a board.

  ## Examples

      {:ok, _} = Feedly.API.Boards.delete_article(client, "board_id", "entry_id")

  """
  @spec delete_article(Config.t(), String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def delete_article(%Config{} = config, tag_id, entry_id) do
    Client.delete(config, "/tags/#{Client.encode_path(tag_id)}/#{Client.encode_path(entry_id)}")
  end
end
