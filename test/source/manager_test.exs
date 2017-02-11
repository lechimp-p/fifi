defmodule Fifi.Source.ManagerTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Manager

  alias Fifi.Source.Manager, as: Manager 
  alias Fifi.Source.Null, as: Null

  setup do
    {:ok, manager} = Manager.start_link()
    {:ok, manager: manager}
  end

  test "list sources", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add_source(manager,  "one", one)
    Manager.add_source(manager, "two", two)
    assert Manager.list(manager) == ["one", "two"]
  end

  test "remove source", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add_source(manager,  "one", one)
    Manager.add_source(manager, "two", two)
    Manager.remove_source(manager, "two")
    assert Manager.list(manager) == ["one"]
  end

  test "starts sources when listener is added", %{manager: manager} do
    {:ok, called} = Agent.start(fn -> false end)
    start_link = fn _f, _ou ->
      Agent.update(called, fn _ -> true end)
      {:ok, called}
    end
    one = %Null{start_link: start_link}
    Manager.add_source(manager, "one", one)
    assert not Agent.get(called, &(&1))
    Manager.add_listener(manager, "one", fn _ -> :ok end)
    assert Agent.get(called, &(&1))
  end

  test "can't add listener for non-existing source", %{manager: manager} do
    assert Manager.add_listener(manager, "one", fn _ -> :ok end) == :error
  end

  test "get reference when adding listener", %{manager: manager} do
    one = %Null{start_link: fn _f, _ou -> {:ok, self()} end}
    Manager.add_source(manager, "one", one)
    {:ok, ref} = Manager.add_listener(manager, "one", fn _ -> :ok end)
    assert is_reference(ref)
  end
end
