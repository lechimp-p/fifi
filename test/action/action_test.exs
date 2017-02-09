defmodule Fifi.Action.ActionPerformerTest do
  use ExUnit.Case
  doctest Fifi.Action.ActionPerformer

  test "action performing" do
    defmodule TestAction do
      @behaviour Fifi.Action.Action

      def act(config, text) do
        assert config == :config
        assert text == :text
      end
    end

    performer = Fifi.Action.ActionPerformer
    performer.perform(:config, :text, TestAction)
  end
end
