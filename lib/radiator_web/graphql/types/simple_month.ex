defmodule RadiatorWeb.GraphQL.Types.SimpleMonth do
  use Absinthe.Schema.Notation

  scalar :simple_month, name: "SimpleMonth" do
    description("""
    The `SimpleMonth` scalar type represents a date with only month precision.
    Example: "2019-03"
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    with {:ok, date} <- Date.from_iso8601("#{value}-01") do
      {:ok, date |> Date.to_iso8601() |> String.slice(0..6)}
    else
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
