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
    Manager.add(manager,  "one", one)
    Manager.add(manager, "two", two)
    assert Manager.list(manager) == ["one", "two"]
  end

  test "remove source", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add(manager,  "one", one)
    Manager.add(manager, "two", two)
    Manager.remove(manager, "two")
    assert Manager.list(manager) == ["one"]
  end
end
