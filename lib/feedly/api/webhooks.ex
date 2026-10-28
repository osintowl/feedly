defmodule Feedly.API.Webhooks do
  @moduledoc """
  API for webhook management.
  """

  alias Feedly.{Client, Config}

  @doc """
  Gets the list of webhooks.

  ## Examples

      {:ok, webhooks} = Feedly.API.Webhooks.list(client)

  """
  @spec list(Config.t()) :: {:ok, list(map())} | {:error, term()}
  def list(%Config{} = config) do
    Client.get(config, "/webhooks")
  end

  @doc """
  Creates or updates a webhook.

  ## Webhook Structure

      %{
        id: "webhook_id",
        url: "https://your-endpoint.com/webhook",
        event: "newEntrySaved",
        streamId: "enterprise/feedly/tag/..."
      }

  ## Supported Events

    * `newEntrySaved` - Triggered when an article is saved to a board
    * `newAnnotation` - Triggered when an annotation is added
    * `newWebAlertEntry` - Triggered when a new article matches a web alert

  ## Examples

      webhook = %{
        id: "my-webhook",
        url: "https://example.com/webhook",
        event: "newEntrySaved",
        streamId: "enterprise/feedly/tag/board-id"
      }

      {:ok, _} = Feedly.API.Webhooks.create_or_update(client, webhook)

  """
  @spec create_or_update(Config.t(), map()) :: {:ok, term()} | {:error, term()}
  def create_or_update(%Config{} = config, webhook) do
    Client.put(config, "/webhooks", webhook)
  end

  @doc """
  Deletes a webhook.

  ## Examples

      {:ok, _} = Feedly.API.Webhooks.delete(client, "webhook_id")

  """
  @spec delete(Config.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def delete(%Config{} = config, webhook_id) do
    Client.delete(config, "/webhooks/#{Client.encode_path(webhook_id)}")
  end
end
