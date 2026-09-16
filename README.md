# Feedly

Elixir client for the Feedly API - easily integrate threat intelligence and news feeds into your Elixir applications.

## Features

- **Complete API Coverage**: Streams, Search, Articles, Boards, Folders, AI Feeds
- **Threat Intelligence**: CVEs, Threat Actors, Malware, IoCs, TTPs, Cyberattacks
- **Automatic Pagination**: Stream through all results with continuation tokens
- **Rate Limiting**: Automatic tracking and warnings for API rate limits
- **Type Safety**: Structured data with TypedStruct schemas
- **Resilient**: Built-in retries and error handling

## Installation

Add `feedly` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:feedly, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
# Create a client
client = Feedly.client(token: "your_api_token")

# Collect articles from a stream
{:ok, %{items: articles, continuation: cont}} = 
  Feedly.stream_contents(client, 
    stream_id: "enterprise/feedly/category/your-stream-id",
    count: 50
  )

# Search for articles
query = %{
  layers: [
    %{type: "matches", parts: [%{text: "ransomware"}], salience: "about"},
    %{type: "language", languages: ["en"]}
  ]
}

{:ok, results} = Feedly.search(client, query, count: 100)

# Stream all articles with automatic pagination
Feedly.stream_all(client, stream_id: "...")
|> Stream.take(1000)
|> Enum.each(&process_article/1)
```

## Threat Intelligence Examples

### CVE Vulnerabilities

```elixir
# Get trending CVEs
{:ok, cves} = Feedly.API.ThreatIntel.CVEs.trending(client)

# Get detailed CVE metadata
{:ok, cve} = Feedly.API.ThreatIntel.CVEs.get(client, "CVE-2024-1234")

# Query the Vulnerability Agent
query = %{
  layers: [
    %{filters: [%{field: "cvssScore", value: %{gte: 9.0}}]},
    %{filters: [%{field: "exploited", value: true}]}
  ],
  count: 50
}

{:ok, results} = Feedly.API.ThreatIntel.CVEs.query_agent(client, query)
```

### Threat Actors

```elixir
# Get trending threat actors
{:ok, actors} = Feedly.API.ThreatIntel.ThreatActors.trending(client)

# Get threat actor details
{:ok, actor} = Feedly.API.ThreatIntel.ThreatActors.get(client, 
  "gz:ta:68391641-859f-4a9a-9a1e-3e5cf71ec376"
)

# Get relationships (IoCs, TTPs, etc.)
{:ok, relationships} = Feedly.API.ThreatIntel.ThreatActors.relationships(client, actor_id)
```

### Malware Families

```elixir
# Get trending malware
{:ok, malware} = Feedly.API.ThreatIntel.Malware.trending(client)

# Get detection rules
{:ok, rules} = Feedly.API.ThreatIntel.Malware.detection_rules(client, malware_id)
```

### Indicators of Compromise (IoCs)

```elixir
# Collect IoCs from a stream
{:ok, result} = Feedly.API.ThreatIntel.IoCs.collect(client,
  stream_id: "enterprise/feedly/category/threat-feed",
  count: 100
)

# Extract IoCs from articles
iocs = Feedly.API.ThreatIntel.IoCs.extract_from_articles(result["items"])
```

## Managing Boards and Folders

```elixir
# List all boards
{:ok, boards} = Feedly.list_boards(client)

# Add articles to a board
{:ok, _} = Feedly.add_to_board(client, "board_id", ["entry_id_1", "entry_id_2"])

# List folders
{:ok, folders} = Feedly.list_folders(client)

# Get AI Feeds
{:ok, %{"enterpriseAlerts" => alerts}} = Feedly.list_ai_feeds(client)
```

## Webhooks

```elixir
# Create a webhook
webhook = %{
  id: "my-webhook",
  url: "https://example.com/webhook",
  event: "newEntrySaved",
  streamId: "enterprise/feedly/tag/board-id"
}

{:ok, _} = Feedly.create_webhook(client, webhook)

# List webhooks
{:ok, webhooks} = Feedly.list_webhooks(client)

# Delete webhook
{:ok, _} = Feedly.delete_webhook(client, "webhook_id")
```

## API Modules

### Core APIs
- `Feedly.API.Streams` - Collect articles from streams
- `Feedly.API.Articles` - Get article metadata
- `Feedly.API.Search` - Search articles
- `Feedly.API.Boards` - Manage team boards
- `Feedly.API.Folders` - Manage team folders
- `Feedly.API.AIFeeds` - AI Feeds (alerts)
- `Feedly.API.Annotations` - Add notes and highlights
- `Feedly.API.Webhooks` - Webhook management
- `Feedly.API.Profile` - User profile

### Threat Intelligence APIs
- `Feedly.API.ThreatIntel.CVEs` - CVE vulnerabilities
- `Feedly.API.ThreatIntel.ThreatActors` - Threat actor intelligence
- `Feedly.API.ThreatIntel.Malware` - Malware families
- `Feedly.API.ThreatIntel.IoCs` - Indicators of Compromise
- `Feedly.API.ThreatIntel.TTPs` - MITRE ATT&CK TTPs
- `Feedly.API.ThreatIntel.Cyberattacks` - Cyberattack intelligence

## Configuration

You can configure the client with various options:

```elixir
client = Feedly.client(
  token: "your_api_token",
  base_url: "https://api.feedly.com/v3",
  timeout: 30_000,          # 30 seconds
  max_retries: 3,
  retry_delay: 1_000        # 1 second
)
```

## Rate Limits

Feedly API has a limit of 100,000 requests per month. The client automatically:
- Tracks rate limit usage via response headers
- Logs warnings when approaching limits (>90%)
- Provides rate limit information in headers:
  - `X-RateLimit-Count` - Current usage
  - `X-RateLimit-Limit` - Total limit
  - `X-RateLimit-Reset` - Seconds until reset

## Error Handling

The client provides structured error types:

```elixir
case Feedly.stream_contents(client, stream_id: "invalid") do
  {:ok, result} -> 
    # Process result
    
  {:error, %Feedly.Error{type: :unauthorized}} ->
    # Handle auth error
    
  {:error, %Feedly.Error{type: :rate_limited, details: details}} ->
    # Handle rate limit
    
  {:error, error} ->
    # Handle other errors
end
```

## Documentation

Full documentation is available at [HexDocs](https://hexdocs.pm/feedly) (once published).

Generate docs locally:

```bash
mix docs
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.

