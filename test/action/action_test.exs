defmodule Fifi.Action.ActionPerformerTest do
  use ExUnit.Case
  doctest Fifi.Action.ActionPerformer

  @performer Fifi.Action.ActionPerformer

  test "action performing" do
    defmodule TestAction do
      @behaviour Fifi.Action.Action

      def act(config, text) do
        assert config == :config
        assert text == :text
        {:ok, text}
      end
    end

    @performer.perform(:config, :text, TestAction)
  end

  test "webhook" do
    action = Fifi.Action.Webhook
    config = %{url: "http://httpbin.org/post"}
    text = "test"

    {:ok, body} = @performer.perform(config, text, action)

    assert Poison.decode!(body)["data"] == text
  end
end
