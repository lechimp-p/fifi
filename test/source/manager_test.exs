defmodule Fifi.Source.ManagerTest do
  use ExUnit.Case, async: true
  doctest Fifi.Source.Manager

  alias Fifi.Source.Manager, as: Manager 
  alias Fifi.Source.Null, as: Null

  setup do
    {:ok, manager} = Manager.start_link()

    {:ok, processes} = Agent.start_link(fn -> [] end)
    start_link = fn _f, _ou ->
      {:ok, pid} = Agent.start_link(fn -> nil end)
      Agent.update(processes, fn ps -> [pid | ps] end)
      {:ok, pid}
    end

    {:ok, manager: manager, processes: processes, start_link: start_link}
  end

  test "can't add source twice", %{manager: manager} do
    one = %Null{}
    Manager.add_source(manager, "one", one)

    {:error, reason} = Manager.add_source(manager, "one", one)
    assert is_binary(reason)
  end

  test "list sources", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add_source(manager, "one", one)
    Manager.add_source(manager, "two", two)
    assert Manager.list(manager) == ["one", "two"]
  end

  test "contains source", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add_source(manager, "one", one)
    Manager.add_source(manager, "two", two)
    assert Manager.contains_source?(manager, "one")
    assert Manager.contains_source?(manager, "two")
    assert not Manager.contains_source?(manager, "three")
  end

  test "remove source", %{manager: manager} do
    one = %Null{id: "one"}
    two = %Null{id: "two"}
    Manager.add_source(manager, "one", one)
    Manager.add_source(manager, "two", two)
    Manager.remove_source(manager, "two")
    assert Manager.list(manager) == ["one"]
  end

  test "can't remove non-existing source", %{manager: manager} do
    {:error, reason} = Manager.remove_source(manager, "one")
    assert is_binary(reason)
  end

  test "starts sources when listener is added", %{manager: manager, processes: processes, start_link: start_link} do
    one = %Null{start_link: start_link}
    Manager.add_source(manager, "one", one)

    assert Agent.get(processes, &(Enum.count(&1))) == 0
    Manager.add_listener(manager, "one", fn _ -> :ok end)
    assert Agent.get(processes, &(Enum.count(&1))) == 1
  end

  test "can't add listener for non-existing source", %{manager: manager} do
    assert Manager.add_listener(manager, "one", fn _ -> :ok end) == :error
  end

  test "get reference and name when adding listener", %{manager: manager} do
    one = %Null{start_link: fn _f, _ou -> {:ok, self()} end}
    Manager.add_source(manager, "one", one)
    {:ok, {name, ref}} = Manager.add_listener(manager, "one", fn _ -> :ok end)
    assert is_reference(ref)
    assert is_binary(name)
  end

  test "stop sources when all listeners are removed", %{manager: manager, processes: processes, start_link: start_link} do
    one = %Null{start_link: start_link}
    Manager.add_source(manager, "one", one)
    {:ok, ref1} = Manager.add_listener(manager, "one", fn _ -> :ok end)
    {:ok, ref2} = Manager.add_listener(manager, "one", fn _ -> :ok end)

    proc = Agent.get(processes, &(hd(&1)))

    assert Process.alive?(proc)

    Manager.remove_listener(manager, ref1)
    assert Process.alive?(proc)

    Manager.remove_listener(manager, ref2)
    assert not Process.alive?(proc)

    # Supervisor does not restart process
    assert Agent.get(processes, &(Enum.count(&1))) == 1
  end

  test "call listeners on update", %{manager: manager} do
    {:ok, called} = Agent.start(fn -> false end)
    update_called = fn v -> Agent.update(called, fn _ -> v end) end

    {:ok, update} = Agent.start(fn -> false end)
    start_link = fn _f, ou ->
      Agent.update(update, fn _ -> ou end)
      {:ok, update}
    end
    one = %Null{start_link: start_link}
    Manager.add_source(manager, "one", one)

    {:ok, ref1} = Manager.add_listener(manager, "one", update_called)
    on_update = Agent.get(update, &(&1))
    on_update.(42)
    assert Agent.get(called, &(&1)) == 42

    Manager.remove_listener(manager, ref1)
    on_update.(23)
    assert Agent.get(called, &(&1)) == 42
  end

  test "restart source processes", %{manager: manager, processes: processes, start_link: start_link} do
    one = %Null{start_link: start_link}
    Manager.add_source(manager, "one", one)

    Manager.add_listener(manager, "one", fn _ -> :ok end)
    pid = Agent.get(processes, &(hd(&1)))

    Process.exit(pid, :kill)

    # Give the supervisor a chance to react.
    Process.sleep(100)

    assert Agent.get(processes, &(Enum.count(&1))) == 2
  end
end
