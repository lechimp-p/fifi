defmodule Fifi.CLI do
  def main(args) do
    args |> parse_args |> process
  end

  def process([]) do
    IO.puts "usage \"fifi --name=some_name\""
  end

  def process(options) do
    IO.puts "Hello #{options[:name]}, welcome to FIFI!"
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [name: :string]
    )
    options
  end
end