defmodule Feedly.API.Articles do
  @moduledoc """
  API for fetching article metadata.
  """

  alias Feedly.{Client, Config}
  alias Feedly.Schemas.Article

  @doc """
  Gets metadata for a single article.

  ## Examples

      {:ok, article} = Feedly.API.Articles.get(client, "article_id")

  """
  @spec get(Config.t(), String.t()) :: {:ok, Article.t()} | {:error, term()}
  def get(%Config{} = config, entry_id) do
    with {:ok, response} <- Client.get(config, "/entries/#{Client.encode_path(entry_id)}") do
      {:ok, Article.from_api(response)}
    end
  end

  @doc """
  Gets metadata for multiple articles.

  ## Examples

      {:ok, articles} = Feedly.API.Articles.get_multiple(client, ["id1", "id2", "id3"])

  """
  @spec get_multiple(Config.t(), list(String.t())) :: {:ok, list(Article.t())} | {:error, term()}
  def get_multiple(%Config{} = config, entry_ids) when is_list(entry_ids) do
    with {:ok, response} <- Client.post(config, "/entries/.mget", entry_ids) do
      articles =
        response
        |> Enum.map(&Article.from_api/1)

      {:ok, articles}
    end
  end
end
