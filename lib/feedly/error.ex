defmodule Feedly.Error do
  @moduledoc """
  Error types for the Feedly client.
  """

  defexception [:type, :message, :status_code, :error_id, :request_id, :details]

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t(),
          status_code: integer() | nil,
          error_id: String.t() | nil,
          request_id: String.t() | nil,
          details: map() | nil
        }

  @type error_type ::
          :bad_request
          | :unauthorized
          | :forbidden
          | :not_found
          | :rate_limited
          | :server_error
          | :network_error
          | :invalid_json
          | :unknown

  @doc """
  Creates a new error from an HTTP response.
  """
  @spec from_response(integer(), map() | binary()) :: t()
  def from_response(status_code, body) when is_map(body) do
    type = status_to_type(status_code)
    message = Map.get(body, "errorMessage", "Unknown error")
    error_id = Map.get(body, "errorId")
    request_id = Map.get(body, "requestId")

    %__MODULE__{
      type: type,
      message: message,
      status_code: status_code,
      error_id: error_id,
      request_id: request_id,
      details: body
    }
  end

  def from_response(status_code, body) when is_binary(body) do
    type = status_to_type(status_code)

    %__MODULE__{
      type: type,
      message: body,
      status_code: status_code
    }
  end

  @doc """
  Creates a new error.
  """
  @spec new(error_type(), String.t(), keyword()) :: t()
  def new(type, message, opts \\ []) do
    %__MODULE__{
      type: type,
      message: message,
      status_code: opts[:status_code],
      error_id: opts[:error_id],
      request_id: opts[:request_id],
      details: opts[:details]
    }
  end

  @impl true
  def message(%__MODULE__{} = error) do
    base = "Feedly API Error (#{error.type}): #{error.message}"

    details =
      [
        error.status_code && "Status: #{error.status_code}",
        error.request_id && "Request ID: #{error.request_id}",
        error.error_id && "Error ID: #{error.error_id}"
      ]
      |> Enum.filter(& &1)
      |> Enum.join(", ")

    if details != "" do
      "#{base} [#{details}]"
    else
      base
    end
  end

  defp status_to_type(400), do: :bad_request
  defp status_to_type(401), do: :unauthorized
  defp status_to_type(403), do: :forbidden
  defp status_to_type(404), do: :not_found
  defp status_to_type(429), do: :rate_limited
  defp status_to_type(status) when status >= 500, do: :server_error
  defp status_to_type(_), do: :unknown
end
