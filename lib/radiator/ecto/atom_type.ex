defmodule Radiator.Ecto.AtomType do
  @moduledoc """
  Custom Type to support `:atom`
  defmodule Post do
    use Ecto.Schema
    schema "posts" do
      field :atom_field, Radiator.Ecto.AtomType
    end
  end
  """

  @behaviour Ecto.Type

  def type, do: :string

  def cast(value) when is_atom(value), do: {:ok, value}
  def cast(value) when is_binary(value), do: {:ok, String.to_existing_atom(value)}
  def cast(_), do: :error

  def load(value), do: {:ok, String.to_existing_atom(value)}

  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(value) when is_binary(value), do: {:ok, value}
  def dump(_), do: :error
end
