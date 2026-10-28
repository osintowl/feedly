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
    {:feedly, "~> 1.1"}
  ]
end
```

## Quick Start

```elixir
client = Feedly.client(token: System.fetch_env!("FEEDLY_TOKEN"))

# Confirms the token. profile is the Feedly account map.
{:ok, profile, rate} = Feedly.API.Profile.get(client)
# rate is %{count: 10005, limit: 100000, reset_in: 1818103} or nil

# Collect articles from a folder, board, or AI Feed.
{:ok, %{items: articles}, _rate} =
  Feedly.API.Streams.get_contents(client,
    stream_id: "enterprise/your-team/category/your-stream-id",
    count: 50
  )

query = %{
  layers: [
    %{type: "matches", parts: [%{text: "ransomware"}], salience: "about"},
    %{type: "language", languages: ["en"]}
  ]
}

{:ok, %{items: results}, _rate} = Feedly.API.Search.query(client, query, count: 100)

Feedly.API.Streams.stream_all(client, stream_id: "enterprise/your-team/category/your-stream-id")
|> Stream.take(1000)
|> Enum.each(&process_article/1)
```

## Threat Intelligence Examples

### CVE Vulnerabilities

```elixir
# Get trending CVEs
{:ok, cves, _rate} = Feedly.API.ThreatIntel.CVEs.trending(client)

# Get detailed CVE metadata
{:ok, cve, _rate} = Feedly.API.ThreatIntel.CVEs.get(client, "CVE-2024-1234")

# Query the Vulnerability Agent
query = %{
  layers: [
    %{filters: [%{field: "cvssScore", value: %{gte: 9.0}}]},
    %{filters: [%{field: "exploited", value: true}]}
  ],
  count: 50
}

{:ok, results, _rate} = Feedly.API.ThreatIntel.CVEs.query_agent(client, query)
```

### Threat Actors

```elixir
# Get trending threat actors
{:ok, actors, _rate} = Feedly.API.ThreatIntel.ThreatActors.trending(client)

# Get threat actor details
{:ok, actor, _rate} = Feedly.API.ThreatIntel.ThreatActors.get(client, 
  "gz:ta:68391641-859f-4a9a-9a1e-3e5cf71ec376"
)

# Get relationships (IoCs, TTPs, etc.)
{:ok, relationships, _rate} = Feedly.API.ThreatIntel.ThreatActors.relationships(client, actor_id)
```

### Malware Families

```elixir
# Get trending malware
{:ok, malware, _rate} = Feedly.API.ThreatIntel.Malware.trending(client)

# Get detection rules
{:ok, rules, _rate} = Feedly.API.ThreatIntel.Malware.detection_rules(client, malware_id)
```

### Indicators of Compromise (IoCs)

```elixir
# Collect IoCs from a stream
{:ok, result, _rate} = Feedly.API.ThreatIntel.IoCs.collect(client,
  stream_id: "enterprise/feedly/category/threat-feed",
  count: 100
)

# Extract IoCs from articles
iocs = Feedly.API.ThreatIntel.IoCs.extract_from_articles(result["items"])
```

## Managing Boards and Folders

```elixir
# List all boards
{:ok, boards, _rate} = Feedly.API.Boards.list(client)

# Add articles to a board
{:ok, _, _rate} = Feedly.API.Boards.add_articles(client, "board_id", ["entry_id_1", "entry_id_2"])

# List folders
{:ok, folders, _rate} = Feedly.API.Folders.list(client)

# Get AI Feeds
{:ok, %{"enterpriseAlerts" => alerts}, _rate} = Feedly.API.AIFeeds.list(client)
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

{:ok, _, _rate} = Feedly.API.Webhooks.create_or_update(client, webhook)

# List webhooks
{:ok, webhooks, _rate} = Feedly.API.Webhooks.list(client)

# Delete webhook
{:ok, _, _rate} = Feedly.API.Webhooks.delete(client, "webhook_id")
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

## Rate limits

Every successful call returns `{:ok, body, rate}`:

```elixir
{:ok, _profile, rate} = Feedly.API.Profile.get(client)

rate.count
# requests used in this period

rate.limit
# monthly cap

rate.reset_in
# seconds until the counter resets
```

`rate` is `%{count: integer, limit: integer, reset_in: integer}`, or `nil` when the response has no `x-ratelimit-count`, `x-ratelimit-limit`, and `x-ratelimit-reset` headers. The client logs a warning once usage passes 90%. On an error, the same map is `error.rate_info`.

`Feedly.RateLimiter.parse_headers/1` builds that map from a raw header map. Req returns header values as lists, and `parse_headers/1` accepts either form.

## Error Handling

The client provides structured error types:

```elixir
case Feedly.API.Streams.get_contents(client, stream_id: "invalid") do
  {:ok, result, _rate} -> 
    # Process result
    
  {:error, %Feedly.Error{type: :unauthorized}} ->
    # Handle auth error
    
  {:error, %Feedly.Error{type: :rate_limited, rate_info: rate}} ->
    # rate.count, rate.limit, and rate.reset_in are still available
    
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

BSD 3-Clause License - see LICENSE file for details.

