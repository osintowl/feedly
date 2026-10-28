defmodule Feedly.APITest do
  use ExUnit.Case, async: true

  alias Feedly.Schemas.Article

  defmodule Adapter do
    def run(request) do
      Process.get(:feedly_req_adapter).(request)
    end
  end

  defp client(adapter) do
    Process.put(:feedly_req_adapter, adapter)
    Feedly.client(token: "test-token", adapter: Feedly.APITest.Adapter)
  end

  defp ok(request, body, status \\ 200) do
    assert request.headers["authorization"] == ["Bearer test-token"]

    response =
      Req.Response.new(
        status: status,
        headers: %{
          "x-ratelimit-count" => ["10"],
          "x-ratelimit-limit" => ["100000"],
          "x-ratelimit-reset" => ["100"]
        },
        body: body
      )

    {request, response}
  end

  test "profile returns the account and reads rate-limit headers" do
    adapter = fn request ->
      assert request.url.path == "/v3/profile"
      ok(request, %{"email" => "ada@example.com", "fullName" => "Ada"})
    end

    assert {:ok, %{"email" => "ada@example.com", "fullName" => "Ada"}} =
             Feedly.API.Profile.get(client(adapter))
  end

  test "profile returns an unauthorized error" do
    adapter = fn request ->
      ok(request, %{"errorMessage" => "token expired"}, 401)
    end

    assert {:error, %Feedly.Error{type: :unauthorized, message: "token expired"}} =
             Feedly.API.Profile.get(client(adapter))
  end

  test "stream contents sends the stream id once" do
    stream_id = "enterprise/team/category/abc"

    adapter = fn request ->
      assert URI.decode_query(request.url.query)["streamId"] == stream_id
      refute request.url.query =~ "%252F"

      ok(request, %{
        "items" => [%{"id" => "entry-1", "title" => "Patch Tuesday"}],
        "continuation" => nil
      })
    end

    assert {:ok, %{items: [%Article{id: "entry-1", title: "Patch Tuesday"}]}} =
             Feedly.API.Streams.get_contents(client(adapter), stream_id: stream_id, count: 5)
  end

  test "cve lookup accepts a CVE id and a full entity id" do
    adapter = fn request ->
      assert URI.decode(request.url.path) == "/v3/entities/vulnerability/m/entity/CVE-2024-1234"
      ok(request, %{"id" => "CVE-2024-1234"})
    end

    feedly = client(adapter)

    assert {:ok, %{"id" => "CVE-2024-1234"}} =
             Feedly.API.ThreatIntel.CVEs.get(feedly, "CVE-2024-1234")

    assert {:ok, %{"id" => "CVE-2024-1234"}} =
             Feedly.API.ThreatIntel.CVEs.get(feedly, "vulnerability/m/entity/CVE-2024-1234")
  end

  test "stream_all returns articles from every page" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    adapter = fn request ->
      call = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

      if call == 0 do
        ok(request, %{
          "items" => [%{"id" => "entry-1", "title" => "First"}],
          "continuation" => "next"
        })
      else
        params = URI.decode_query(request.url.query || "")
        assert params["continuation"] == "next"

        ok(request, %{
          "items" => [%{"id" => "entry-2", "title" => "Second"}],
          "continuation" => nil
        })
      end
    end

    articles =
      adapter
      |> client()
      |> Feedly.API.Streams.stream_all(stream_id: "enterprise/team/category/abc")
      |> Enum.to_list()

    assert [%Article{id: "entry-1"}, %Article{id: "entry-2"}] = articles
  end

  test "stream_all raises when a later page fails" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    adapter = fn request ->
      call = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

      if call == 0 do
        ok(request, %{
          "items" => [%{"id" => "entry-1", "title" => "First"}],
          "continuation" => "next"
        })
      else
        ok(request, %{"errorMessage" => "denied"}, 401)
      end
    end

    assert_raise Feedly.Error, ~r/denied/, fn ->
      adapter
      |> client()
      |> Feedly.API.Streams.stream_all(stream_id: "enterprise/team/category/abc")
      |> Enum.to_list()
    end
  end

  test "lists team boards from the enterprise tags endpoint" do
    adapter = fn request ->
      assert request.method == :get
      assert request.url.path == "/v3/enterprise/tags"
      ok(request, [%{"id" => "enterprise/team/tag/board-1", "label" => "Watch"}])
    end

    assert {:ok, [%{"label" => "Watch"}]} = Feedly.API.Boards.list(client(adapter))
  end

  test "adds and removes articles with the documented board paths" do
    board_id = "enterprise/team/tag/board-1"

    adapter = fn request ->
      path = URI.decode(request.url.path)

      cond do
        request.method == :put ->
          assert path == "/v3/tags/#{board_id}"
          assert Jason.decode!(request.body) == %{"entryId" => "entry-1"}

        request.method == :delete ->
          assert path == "/v3/tags/#{board_id}/entry-1"
      end

      ok(request, %{})
    end

    feedly = client(adapter)
    assert {:ok, %{}} = Feedly.API.Boards.add_articles(feedly, board_id, ["entry-1"])
    assert {:ok, %{}} = Feedly.API.Boards.delete_article(feedly, board_id, "entry-1")
  end

  test "extracts indicators from raw articles and article structs" do
    raw = [
      %{
        "id" => "entry-1",
        "indicatorsOfCompromise" => %{"mentions" => [%{"text" => "1.2.3.4", "type" => "ip"}]}
      }
    ]

    struct = %Article{
      id: "entry-2",
      indicators_of_compromise: %{"mentions" => [%{"text" => "evil.example", "type" => "domain"}]}
    }

    assert Feedly.API.ThreatIntel.IoCs.extract_from_articles(raw ++ [struct]) == [
             %{"text" => "1.2.3.4", "type" => "ip", "article_id" => "entry-1"},
             %{"text" => "evil.example", "type" => "domain", "article_id" => "entry-2"}
           ]
  end
end
