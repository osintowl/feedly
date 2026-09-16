defmodule Feedly.Schemas.Article do
  @moduledoc """
  Represents a Feedly article with all enrichments.
  """
  use TypedStruct

  typedstruct do
    field(:id, String.t())
    field(:title, String.t())
    field(:author, String.t())
    field(:origin_id, String.t())
    field(:canonical_url, String.t())
    field(:language, String.t())

    # Timestamps (epoch milliseconds)
    field(:published, integer())
    field(:crawled, integer())
    field(:updated, integer())
    field(:recrawled, integer())

    # Content
    field(:content, map())
    field(:summary, map())
    field(:full_content, String.t())

    # Visual
    field(:visual, map())

    # Source information
    field(:origin, map())
    field(:alternate, list(map()))

    # Organization
    field(:categories, list(map()))
    field(:tags, list(map()))
    field(:sources, list(map()))

    # Read status
    field(:unread, boolean())
    field(:read_time, integer())

    # AI enrichments
    field(:entities, list(map()))
    field(:common_topics, list(map()))
    field(:business_events, list(map()))
    field(:leo_summary, map())

    # Engagement
    field(:engagement, integer())
    field(:engagement_rate, float())

    # Related content
    field(:linked, list(map()))
    field(:duplicates, list(map()))
    field(:clusters, list(map()))
    field(:featured_meme, map())

    # User annotations
    field(:annotations, list(map()))

    # Threat Intelligence
    field(:indicators_of_compromise, map())
    field(:attack_navigator, map())
    field(:estimated_cvss, map())

    # AI Actions
    field(:ai_actions, list(map()))

    # Search
    field(:preview_search_terms, map())

    # Twitter/Reddit specific
    field(:author_details, map())
  end

  @doc """
  Parses an article from API response data.
  """
  @spec from_api(map()) :: t()
  def from_api(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      title: data["title"],
      author: data["author"],
      origin_id: data["originId"],
      canonical_url: data["canonicalUrl"],
      language: data["language"],
      published: data["published"],
      crawled: data["crawled"],
      updated: data["updated"],
      recrawled: data["recrawled"],
      content: data["content"],
      summary: data["summary"],
      full_content: data["fullContent"],
      visual: data["visual"],
      origin: data["origin"],
      alternate: data["alternate"] || [],
      categories: data["categories"] || [],
      tags: data["tags"] || [],
      sources: data["sources"] || [],
      unread: data["unread"],
      read_time: data["readTime"],
      entities: data["entities"] || [],
      common_topics: data["commonTopics"] || [],
      business_events: data["businessEvents"] || [],
      leo_summary: data["leoSummary"],
      engagement: data["engagement"],
      engagement_rate: data["engagementRate"],
      linked: data["linked"] || [],
      duplicates: data["duplicates"] || [],
      clusters: data["clusters"] || [],
      featured_meme: data["featuredMeme"],
      annotations: data["annotations"] || [],
      indicators_of_compromise: data["indicatorsOfCompromise"],
      attack_navigator: data["attackNavigator"],
      estimated_cvss: data["estimatedCVSS"],
      ai_actions: data["aiActions"] || [],
      preview_search_terms: data["previewSearchTerms"],
      author_details: data["authorDetails"]
    }
  end

  @doc """
  Extracts HTML content from an article, following the priority hierarchy:
  1. Linked entries (for aggregation sources like Reddit/Twitter)
  2. fullContent
  3. content.content
  4. summary.content
  """
  @spec extract_content(t()) :: String.t() | nil
  def extract_content(%__MODULE__{} = article) do
    cond do
      # Check linked entries first
      article.linked && length(article.linked) > 0 ->
        article.linked
        |> Enum.find_value(fn linked ->
          extract_content_fields(linked)
        end)

      # Then check main article fields
      true ->
        extract_content_fields(article)
    end
  end

  defp extract_content_fields(%__MODULE__{} = article) do
    cond do
      is_binary(article.full_content) ->
        article.full_content

      is_map(article.content) && is_binary(article.content["content"]) ->
        article.content["content"]

      is_map(article.summary) && is_binary(article.summary["content"]) ->
        article.summary["content"]

      true ->
        nil
    end
  end

  defp extract_content_fields(map) when is_map(map) do
    cond do
      is_binary(map["fullContent"]) -> map["fullContent"]
      is_map(map["content"]) && is_binary(map["content"]["content"]) -> map["content"]["content"]
      is_map(map["summary"]) && is_binary(map["summary"]["content"]) -> map["summary"]["content"]
      true -> nil
    end
  end

  defp extract_content_fields(_), do: nil

  @doc """
  Gets the article URL, preferring canonical URL over alternate.
  """
  @spec get_url(t()) :: String.t() | nil
  def get_url(%__MODULE__{canonical_url: url}) when is_binary(url), do: url

  def get_url(%__MODULE__{alternate: [%{"href" => url} | _]}) when is_binary(url), do: url
  def get_url(%__MODULE__{alternate: []}), do: nil
  def get_url(_), do: nil
end
