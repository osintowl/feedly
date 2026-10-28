defmodule Feedly do
  @moduledoc """
  Elixir client for the Feedly API.

  Feedly's API is an easy-to-integrate REST API that allows you to automate 
  workflows to quickly share intelligence with leadership and operations teams.

  Successful calls return `{:ok, body, rate_info}`. `rate_info` is a
  `t:Feedly.RateLimiter.rate_info/0` or `nil`.

  ## Quick Start

      client = Feedly.client(token: System.fetch_env!("FEEDLY_TOKEN"))

      {:ok, profile, rate} = Feedly.API.Profile.get(client)
      # rate => %{count: 10005, limit: 100000, reset_in: 1818103}

      {:ok, %{items: articles}, _rate} =
        Feedly.API.Streams.get_contents(client,
          stream_id: "enterprise/feedly/category/...",
          count: 50
        )

      query = %{
        layers: [
          %{type: "matches", parts: [%{text: "ransomware"}], salience: "about"},
          %{type: "language", languages: ["en"]}
        ]
      }

      {:ok, %{items: results}, _rate} = Feedly.API.Search.query(client, query)

      Feedly.API.Streams.stream_all(client, stream_id: "...")
      |> Stream.take(1000)
      |> Enum.to_list()

  ## API Modules

    * `Feedly.API.Streams` - Collect articles from streams
    * `Feedly.API.Articles` - Get article metadata
    * `Feedly.API.Search` - Search articles
    * `Feedly.API.Boards` - Manage team boards
    * `Feedly.API.Folders` - Manage team folders
    * `Feedly.API.AIFeeds` - AI Feeds (alerts)
    * `Feedly.API.Annotations` - Add notes and highlights
    * `Feedly.API.Webhooks` - Webhook management
    * `Feedly.API.Profile` - User profile

  ## Threat Intelligence APIs

    * `Feedly.API.ThreatIntel.CVEs` - CVE vulnerabilities
    * `Feedly.API.ThreatIntel.ThreatActors` - Threat actor intelligence
    * `Feedly.API.ThreatIntel.Malware` - Malware families
    * `Feedly.API.ThreatIntel.IoCs` - Indicators of Compromise
    * `Feedly.API.ThreatIntel.TTPs` - MITRE ATT&CK TTPs
    * `Feedly.API.ThreatIntel.Cyberattacks` - Cyberattack intelligence

  ## Rate Limits

  Feedly API has a limit of 100,000 requests per month. The client automatically
  tracks rate limits via response headers and logs warnings when approaching limits.

  ## Configuration

      client = Feedly.client(
        token: "your_api_token",
        base_url: "https://api.feedly.com/v3",
        timeout: 30_000,
        max_retries: 3,
        retry_delay: 1_000
      )

  """

  alias Feedly.Config

  # Public API convenience aliases
  alias Feedly.API.Streams
  alias Feedly.API.Articles
  alias Feedly.API.Search
  alias Feedly.API.Boards
  alias Feedly.API.Folders
  alias Feedly.API.AIFeeds
  alias Feedly.API.Annotations
  alias Feedly.API.Webhooks
  alias Feedly.API.Profile

  defdelegate stream_contents(config, opts), to: Streams, as: :get_contents
  defdelegate stream_all(config, opts), to: Streams, as: :stream_all

  defdelegate get_article(config, entry_id), to: Articles, as: :get
  defdelegate get_articles(config, entry_ids), to: Articles, as: :get_multiple

  defdelegate search(config, query, opts \\ []), to: Search, as: :query
  defdelegate search_all(config, query, opts \\ []), to: Search, as: :stream_all

  defdelegate list_boards(config), to: Boards, as: :list
  defdelegate add_to_board(config, tag_id, entry_ids), to: Boards, as: :add_articles
  defdelegate remove_from_board(config, tag_id, entry_id), to: Boards, as: :delete_article

  defdelegate list_folders(config, opts \\ []), to: Folders, as: :list
  defdelegate list_ai_feeds(config), to: AIFeeds, as: :list

  defdelegate create_annotation(config, annotation), to: Annotations, as: :create

  defdelegate list_webhooks(config), to: Webhooks, as: :list
  defdelegate create_webhook(config, webhook), to: Webhooks, as: :create_or_update
  defdelegate delete_webhook(config, webhook_id), to: Webhooks, as: :delete

  defdelegate get_profile(config), to: Profile, as: :get

  @doc """
  Creates a new Feedly client configuration.

  ## Options

    * `:token` - Feedly API token (required)
    * `:base_url` - Base URL for API requests (default: "https://api.feedly.com/v3")
    * `:timeout` - Request timeout in milliseconds (default: 30000)
    * `:max_retries` - Maximum number of retries on failure (default: 3)
    * `:retry_delay` - Delay between retries in milliseconds (default: 1000)

  ## Examples

      client = Feedly.client(token: "my_token")

  """
  @spec client(keyword()) :: Config.t()
  def client(opts \\ []) when is_list(opts) do
    Config.new(opts)
  end
end
