defmodule Action do
  @moduledoc ~S"""
  Specification of how an action must look like.
  """
  @type config :: Map

  @callback act(config, String) :: nil
end

defmodule ActionPerformer do
  @default_action Stdout

  def perform(config, text, action \\ @default_action) do
    action.act config, text
  end
end

defmodule Stdout do
  @behaviour Action

  def act(%{prefix: prefix}, text) do
    IO.puts "#{prefix}#{text}"
  end

  def act(_, text) do
    IO.puts text
  end
end

defmodule Webhook do
  @behaviour Action

  def act(_, text) do
    text
  end
end

defmodule Tweet do
  @behaviour Action

  def act(_, text) do
    text
  end
end
