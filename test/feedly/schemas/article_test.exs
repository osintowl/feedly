defmodule Feedly.Schemas.ArticleTest do
  use ExUnit.Case, async: true

  alias Feedly.Schemas.Article

  describe "from_api/1" do
    test "parses article from API response" do
      data = %{
        "id" => "article-123",
        "title" => "Test Article",
        "author" => "John Doe",
        "published" => 1_609_459_200_000,
        "entities" => [%{"type" => "org", "label" => "Microsoft"}],
        "commonTopics" => [%{"type" => "topic", "label" => "Cybersecurity"}]
      }

      article = Article.from_api(data)

      assert article.id == "article-123"
      assert article.title == "Test Article"
      assert article.author == "John Doe"
      assert article.published == 1_609_459_200_000
      assert length(article.entities) == 1
      assert length(article.common_topics) == 1
    end

    test "handles missing optional fields" do
      data = %{
        "id" => "article-123",
        "title" => "Test Article"
      }

      article = Article.from_api(data)

      assert article.id == "article-123"
      assert article.entities == []
      assert article.tags == []
    end
  end

  describe "extract_content/1" do
    test "extracts from full_content" do
      article = %Article{
        full_content: "Full content here",
        content: %{"content" => "Partial content"}
      }

      assert Article.extract_content(article) == "Full content here"
    end

    test "extracts from content when full_content is missing" do
      article = %Article{
        content: %{"content" => "Content here"}
      }

      assert Article.extract_content(article) == "Content here"
    end

    test "extracts from summary when others are missing" do
      article = %Article{
        summary: %{"content" => "Summary here"}
      }

      assert Article.extract_content(article) == "Summary here"
    end

    test "prioritizes linked entries" do
      article = %Article{
        full_content: "Main content",
        linked: [
          %{"fullContent" => "Linked content here"}
        ]
      }

      assert Article.extract_content(article) == "Linked content here"
    end

    test "returns nil when no content available" do
      article = %Article{}
      assert Article.extract_content(article) == nil
    end
  end

  describe "get_url/1" do
    test "returns canonical URL when available" do
      article = %Article{
        canonical_url: "https://example.com/canonical",
        alternate: [%{"href" => "https://example.com/alternate"}]
      }

      assert Article.get_url(article) == "https://example.com/canonical"
    end

    test "falls back to alternate URL" do
      article = %Article{
        alternate: [%{"href" => "https://example.com/alternate"}]
      }

      assert Article.get_url(article) == "https://example.com/alternate"
    end

    test "returns nil when no URL available" do
      article = %Article{alternate: []}
      assert Article.get_url(article) == nil
    end
  end
end
