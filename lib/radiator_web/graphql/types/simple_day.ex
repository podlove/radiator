defmodule RadiatorWeb.GraphQL.Types.SimpleDay do
  use Absinthe.Schema.Notation

  scalar :simple_day, name: "SimpleDay" do
    description("""
    The `SimpleDay` scalar type represents a date with day precision in form YYYY-MM-DD.
    Example: "2019-03-28"
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    with {:ok, date} <- Date.from_iso8601(value) do
      {:ok, Date.to_iso8601(date)}
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
