defmodule Fifi.Source.SPON do
  @moduledoc """
  A source that watches the topmost headline on www.spiegel.de.
  """

  defmodule Handle do
    defstruct pid: ()
  end

  defmodule Worker do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init([]) do
      schedule_check()
      {:ok, %{last_title: ()}}
    end

    def handle_info(:check, state) do
      title = check(state)
      schedule_check()
      {:noreply, %{state | last_title: title}}
    end

    defp schedule_check() do
      Process.send_after(self(), :check, 10_000)
    end

    defp check(state) do
      title = Fifi.Source.SPON.get_title()
      IO.puts title
      title
    end
  end

  def get_title do
    HTTPoison.get!("http://www.spiegel.de").body
      |> Floki.find(".article-title")
      |> Floki.find(".headline")
      |> hd()
      |> Floki.text()
      |> String.trim()
  end
end

defimpl Fifi.Source.Source, for: Fifi.Source.SPON.Handle do
  def description(_source), do: "Watches topmost headline of www.spiegel.de."
end
