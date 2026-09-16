defmodule Feedly.ConfigTest do
  use ExUnit.Case, async: true

  alias Feedly.Config

  describe "new/1" do
    test "creates config with required token" do
      config = Config.new(token: "test_token")
      assert config.token == "test_token"
      assert config.base_url == "https://api.feedly.com/v3"
    end

    test "accepts custom options" do
      config =
        Config.new(
          token: "test_token",
          base_url: "https://custom.example.com",
          timeout: 60_000
        )

      assert config.token == "test_token"
      assert config.base_url == "https://custom.example.com"
      assert config.timeout == 60_000
    end

    test "raises when token is missing" do
      assert_raise KeyError, fn ->
        Config.new([])
      end
    end
  end

  describe "valid?/1" do
    test "returns true for valid config" do
      config = Config.new(token: "test_token")
      assert Config.valid?(config)
    end

    test "returns false for invalid config" do
      config = %Config{token: nil}
      refute Config.valid?(config)

      config = %Config{token: ""}
      refute Config.valid?(config)
    end
  end
end
