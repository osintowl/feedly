defmodule Feedly.Client do
  @moduledoc """
  HTTP client for making requests to the Feedly API.
  """

  alias Feedly.{Config, Error, RateLimiter}

  @type response(body) ::
          {:ok, body, RateLimiter.rate_info() | nil} | {:error, Error.t()}

  @type response :: response(term())

  @doc """
  Makes a GET request to the Feedly API.
  """
  @spec get(Config.t(), String.t(), keyword()) :: response()
  def get(%Config{} = config, path, opts \\ []) do
    request(config, :get, path, opts)
  end

  @doc """
  Makes a POST request to the Feedly API.
  """
  @spec post(Config.t(), String.t(), map() | list(), keyword()) :: response()
  def post(%Config{} = config, path, body, opts \\ []) do
    opts = Keyword.put(opts, :json, body)
    request(config, :post, path, opts)
  end

  @doc """
  Makes a PUT request to the Feedly API.
  """
  @spec put(Config.t(), String.t(), map() | list(), keyword()) :: response()
  def put(%Config{} = config, path, body, opts \\ []) do
    opts = Keyword.put(opts, :json, body)
    request(config, :put, path, opts)
  end

  @doc """
  Makes a DELETE request to the Feedly API.
  """
  @spec delete(Config.t(), String.t(), keyword()) :: response()
  def delete(%Config{} = config, path, opts \\ []) do
    request(config, :delete, path, opts)
  end

  defp request(config, method, path, opts) do
    url = build_url(config, path)
    params = Keyword.get(opts, :params, %{})
    json = Keyword.get(opts, :json)

    req_opts = [
      method: method,
      url: url,
      headers: build_headers(config, json != nil),
      params: stringify_params(params),
      receive_timeout: config.timeout,
      retry: :transient,
      max_retries: config.max_retries,
      retry_delay: fn attempt -> config.retry_delay * (attempt + 1) end
    ]

    req_opts =
      case config.adapter do
        nil -> req_opts
        adapter -> Keyword.put(req_opts, :adapter, adapter)
      end

    req_opts =
      if json do
        Keyword.put(req_opts, :json, json)
      else
        req_opts
      end

    case Req.request(req_opts) do
      {:ok, %Req.Response{status: status, body: body, headers: headers}}
      when status in 200..299 ->
        rate_info = RateLimiter.parse_headers(headers)
        warn_if_near_limit(rate_info)
        {:ok, body, rate_info}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        error = %{
          Error.from_response(status, body)
          | rate_info: RateLimiter.parse_headers(headers)
        }

        {:error, error}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, Error.new(:network_error, "Network error: #{inspect(reason)}")}

      {:error, reason} ->
        {:error, Error.new(:unknown, "Request failed: #{inspect(reason)}")}
    end
  end

  defp warn_if_near_limit(nil), do: :ok

  defp warn_if_near_limit(rate_info) do
    if RateLimiter.should_wait?(rate_info) do
      require Logger

      Logger.warning(
        "Feedly API rate limit approaching: #{rate_info.count}/#{rate_info.limit}, resets in #{rate_info.reset_in}s"
      )
    end
  end

  defp build_url(%Config{base_url: base_url}, path) do
    # Remove leading slash from path if present
    path = String.trim_leading(path, "/")
    "#{base_url}/#{path}"
  end

  defp build_headers(%Config{token: token}, has_body) do
    headers = [
      {"authorization", "Bearer #{token}"},
      {"accept", "application/json"}
    ]

    if has_body do
      [{"content-type", "application/json"} | headers]
    else
      headers
    end
  end

  @doc false
  def encode_path(id) when is_binary(id) do
    URI.encode(id, &URI.char_unreserved?/1)
  end

  defp stringify_params(params) do
    Map.new(params, fn {key, value} -> {key, to_string(value)} end)
  end
end
