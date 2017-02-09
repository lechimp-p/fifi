defmodule Fifi.Action.Action do
  @moduledoc ~S"""
  Specification of how an action must look like.
  """
  @type config :: Map

  @callback act(config, String) :: Tuple
end

defmodule Fifi.Action.ActionPerformer do
  @default_action Fifi.Action.Stdout

  def perform(config, text, action \\ @default_action) do
    action.act config, text
  end
end

defmodule Fifi.Action.Stdout do
  @behaviour Fifi.Action.Action

  def act(%{prefix: prefix}, text) do
    IO.puts "#{prefix}#{text}"
    {:ok, text}
  end

  def act(_, text) do
    IO.puts text
    {:ok, text}
  end
end

defmodule Fifi.Action.Webhook do
  @behaviour Fifi.Action.Action

  def act(%{url: url}, text) do
    body = HTTPoison.post!(url, text).body
    {:ok, body}
  end
end

defmodule Fifi.Action.Tweet do
  @behaviour Fifi.Action.Action

  def act(_, text) do
    {:ok, text}
  end
end
