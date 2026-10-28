defmodule Feedly.API.Articles do
  @moduledoc """
  API for fetching article metadata.
  """

  alias Feedly.{Client, Config}
  alias Feedly.Schemas.Article

  @doc """
  Gets metadata for a single article.

  ## Examples

      {:ok, article, _rate} = Feedly.API.Articles.get(client, "article_id")

  """
  @spec get(Config.t(), String.t()) ::
          {:ok, Article.t(), Feedly.RateLimiter.rate_info() | nil} | {:error, Feedly.Error.t()}
  def get(%Config{} = config, entry_id) do
    with {:ok, response, rate_info} <-
           Client.get(config, "/entries/#{Client.encode_path(entry_id)}") do
      {:ok, Article.from_api(response), rate_info}
    end
  end

  @doc """
  Gets metadata for multiple articles.

  ## Examples

      {:ok, articles, _rate} = Feedly.API.Articles.get_multiple(client, ["id1", "id2", "id3"])

  """
  @spec get_multiple(Config.t(), list(String.t())) ::
          {:ok, list(Article.t()), Feedly.RateLimiter.rate_info() | nil}
          | {:error, Feedly.Error.t()}
  def get_multiple(%Config{} = config, entry_ids) when is_list(entry_ids) do
    with {:ok, response, rate_info} <- Client.post(config, "/entries/.mget", entry_ids) do
      articles = Enum.map(response, &Article.from_api/1)
      {:ok, articles, rate_info}
    end
  end
end
