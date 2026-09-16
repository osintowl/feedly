defmodule Examples do
  @moduledoc """
  Example usage of the Feedly client.

  To run these examples, you need to set the FEEDLY_TOKEN environment variable:

      export FEEDLY_TOKEN="your_feedly_api_token"
      iex -S mix
      Examples.basic_usage()

  """

  @doc """
  Basic usage example: fetching articles from a stream.
  """
  def basic_usage do
    # Get token from environment
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"

    # Create client
    client = Feedly.client(token: token)

    # Get user profile
    case Feedly.get_profile(client) do
      {:ok, profile} ->
        IO.puts("Connected as: #{profile["fullName"]} (#{profile["email"]})")

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Collecting articles from a stream with pagination.
  """
  def collect_articles(stream_id, count \\ 20) do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Collecting #{count} articles from stream: #{stream_id}")

    case Feedly.stream_contents(client, stream_id: stream_id, count: count) do
      {:ok, %{items: articles, continuation: cont}} ->
        IO.puts("\nFound #{length(articles)} articles")

        articles
        |> Enum.take(5)
        |> Enum.each(fn article ->
          IO.puts("\n---")
          IO.puts("Title: #{article.title}")
          IO.puts("Published: #{format_timestamp(article.published)}")
          IO.puts("URL: #{Feedly.Schemas.Article.get_url(article)}")
        end)

        if cont do
          IO.puts("\nMore articles available (continuation: #{String.slice(cont, 0..20)}...)")
        end

        {:ok, articles}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Streaming all articles with automatic pagination.
  """
  def stream_all_articles(stream_id, limit \\ 100) do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Streaming up to #{limit} articles from: #{stream_id}")

    articles =
      Feedly.stream_all(client, stream_id: stream_id, count: 50)
      |> Stream.take(limit)
      |> Enum.to_list()

    IO.puts("\nCollected #{length(articles)} articles")
    {:ok, articles}
  end

  @doc """
  Example: Searching for articles.
  """
  def search_example(search_term) do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    query = %{
      layers: [
        %{type: "matches", parts: [%{text: search_term}], salience: "about"},
        %{type: "language", languages: ["en"]}
      ]
    }

    IO.puts("Searching for: #{search_term}")

    case Feedly.search(client, query, count: 10) do
      {:ok, %{items: articles}} ->
        IO.puts("\nFound #{length(articles)} articles")

        articles
        |> Enum.take(5)
        |> Enum.each(fn article ->
          IO.puts("\n---")
          IO.puts("Title: #{article.title}")
          IO.puts("Published: #{format_timestamp(article.published)}")
        end)

        {:ok, articles}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Getting trending CVEs.
  """
  def trending_cves do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Fetching trending CVEs...")

    case Feedly.API.ThreatIntel.CVEs.trending(client, count: 10) do
      {:ok, cves} ->
        IO.puts("\nTop Trending CVEs:")

        cves
        |> Enum.take(10)
        |> Enum.each(fn cve ->
          IO.puts("\n---")
          IO.puts("CVE: #{cve["id"] || "N/A"}")
          IO.puts("Score: #{cve["cvssScore"] || "N/A"}")
          IO.puts("Mentions: #{cve["mentionCount"] || 0}")
        end)

        {:ok, cves}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Getting CVE details.
  """
  def cve_details(cve_id) do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Fetching details for: #{cve_id}")

    case Feedly.API.ThreatIntel.CVEs.get(client, cve_id) do
      {:ok, cve} ->
        IO.puts("\nCVE Details:")
        IO.puts("ID: #{cve["id"]}")
        IO.puts("Description: #{cve["description"]}")
        IO.puts("CVSS Score: #{cve["cvssScore"]}")
        IO.puts("Has Exploit: #{cve["hasExploit"]}")
        IO.puts("Has Patch: #{cve["hasPatch"]}")

        {:ok, cve}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Listing AI Feeds.
  """
  def list_ai_feeds do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Listing AI Feeds...")

    case Feedly.list_ai_feeds(client) do
      {:ok, %{"enterpriseAlerts" => alerts}} ->
        IO.puts("\nEnterprise AI Feeds:")

        alerts
        |> Enum.each(fn alert ->
          IO.puts("\n---")
          IO.puts("Label: #{alert["label"]}")
          IO.puts("ID: #{alert["id"]}")
          IO.puts("Velocity: #{alert["velocity"]} articles/day")
        end)

        {:ok, alerts}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Example: Getting threat actor information.
  """
  def trending_threat_actors do
    token = System.get_env("FEEDLY_TOKEN") || raise "FEEDLY_TOKEN not set"
    client = Feedly.client(token: token)

    IO.puts("Fetching trending threat actors...")

    case Feedly.API.ThreatIntel.ThreatActors.trending(client, count: 10) do
      {:ok, actors} ->
        IO.puts("\nTop Trending Threat Actors:")

        actors
        |> Enum.take(10)
        |> Enum.each(fn actor ->
          IO.puts("\n---")
          IO.puts("Name: #{actor["label"] || "N/A"}")
          IO.puts("Mentions: #{actor["mentionCount"] || 0}")
        end)

        {:ok, actors}

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
        :error
    end
  end

  defp format_timestamp(nil), do: "N/A"

  defp format_timestamp(epoch_ms) when is_integer(epoch_ms) do
    epoch_ms
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S UTC")
  end

  defp format_timestamp(_), do: "N/A"
end
