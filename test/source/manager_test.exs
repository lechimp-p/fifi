defmodule Fifi.Source.ManagerTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Manager

  alias Fifi.Source.Manager, as: Manager 
  alias Fifi.Source.Null, as: Null

  setup do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    {:ok, manager} = Manager.start_link([{"one", one}, {"two", two}])
    {:ok, manager: manager}
  end

  test "manager", %{manager: manager} do
    assert Manager.list(manager) == ["one", "two"]
  end
end
