defmodule Feedly.Config do
  @moduledoc """
  Configuration management for the Feedly client.
  """

  @type t :: %__MODULE__{
          token: String.t(),
          base_url: String.t(),
          timeout: pos_integer(),
          max_retries: non_neg_integer(),
          retry_delay: pos_integer(),
          adapter: module() | nil
        }

  defstruct token: nil,
            base_url: "https://api.feedly.com/v3",
            timeout: 30_000,
            max_retries: 3,
            retry_delay: 1_000,
            adapter: nil

  @doc """
  Creates a new configuration struct.

  ## Options

    * `:token` - Feedly API token (required)
    * `:base_url` - Base URL for API requests (default: "https://api.feedly.com/v3")
    * `:timeout` - Request timeout in milliseconds (default: 30000)
    * `:max_retries` - Maximum number of retries on failure (default: 3)
    * `:retry_delay` - Delay between retries in milliseconds (default: 1000)
    * `:adapter` - Req adapter module. Defaults to Req's Finch adapter. Pass a module with `run/1` to stub HTTP in tests.

  ## Examples

      iex> Feedly.Config.new(token: "my_token")
      %Feedly.Config{token: "my_token", ...}

  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    token = Keyword.get(opts, :token)

    unless is_binary(token) and byte_size(token) > 0 do
      raise ArgumentError, "Feedly client requires a non-empty :token"
    end

    %__MODULE__{
      token: token,
      base_url: Keyword.get(opts, :base_url, "https://api.feedly.com/v3"),
      timeout: Keyword.get(opts, :timeout, 30_000),
      max_retries: Keyword.get(opts, :max_retries, 3),
      retry_delay: Keyword.get(opts, :retry_delay, 1_000),
      adapter: Keyword.get(opts, :adapter)
    }
  end

  @doc """
  Validates the configuration.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{token: token}) when is_binary(token) and byte_size(token) > 0 do
    true
  end

  def valid?(_), do: false
end
