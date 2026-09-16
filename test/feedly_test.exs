defmodule FeedlyTest do
  use ExUnit.Case, async: true
  doctest Feedly

  test "client creates config" do
    config = Feedly.client(token: "test_token")
    assert %Feedly.Config{} = config
    assert config.token == "test_token"
  end
end
