defmodule Feedly.ErrorTest do
  use ExUnit.Case, async: true

  alias Feedly.Error

  describe "from_response/2" do
    test "creates error from JSON response" do
      body = %{
        "errorMessage" => "Invalid JSON",
        "errorId" => "xyz.123",
        "requestId" => "abc-456"
      }

      error = Error.from_response(400, body)

      assert error.type == :bad_request
      assert error.message == "Invalid JSON"
      assert error.status_code == 400
      assert error.error_id == "xyz.123"
      assert error.request_id == "abc-456"
    end

    test "creates error from string response" do
      error = Error.from_response(500, "Internal Server Error")

      assert error.type == :server_error
      assert error.message == "Internal Server Error"
      assert error.status_code == 500
    end

    test "maps status codes to error types" do
      assert Error.from_response(400, %{}).type == :bad_request
      assert Error.from_response(401, %{}).type == :unauthorized
      assert Error.from_response(403, %{}).type == :forbidden
      assert Error.from_response(404, %{}).type == :not_found
      assert Error.from_response(429, %{}).type == :rate_limited
      assert Error.from_response(500, %{}).type == :server_error
      assert Error.from_response(503, %{}).type == :server_error
    end
  end

  describe "new/3" do
    test "creates error with type and message" do
      error = Error.new(:unauthorized, "Invalid token")

      assert error.type == :unauthorized
      assert error.message == "Invalid token"
    end

    test "creates error with options" do
      error = Error.new(:rate_limited, "Rate limit exceeded", status_code: 429)

      assert error.type == :rate_limited
      assert error.message == "Rate limit exceeded"
      assert error.status_code == 429
    end
  end

  describe "message/1" do
    test "formats error message" do
      error = Error.new(:unauthorized, "Invalid token", status_code: 401, request_id: "req-123")

      message = Exception.message(error)

      assert message =~ "Feedly API Error (unauthorized): Invalid token"
      assert message =~ "Status: 401"
      assert message =~ "Request ID: req-123"
    end
  end
end
