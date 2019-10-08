defmodule Radiator.Perm.Ecto.PermissionType do
  use Ecto.Type

  alias Ecto.Type

  use Radiator.Constants

  @allowed_values @permission_values

  def allowed_values do
    @allowed_values
  end

  @impl Type
  def type, do: :binary

  @impl Type
  def cast(binary) when is_binary(binary), do: cast(String.to_existing_atom(binary))

  @impl Type
  def cast(atom) when is_atom(atom) do
    if atom in @allowed_values do
      {:ok, atom}
    else
      :error
    end
  end

  @impl Type
  def load(data) when is_binary(data) do
    {:ok, String.to_existing_atom(data)}
  end

  @impl Type
  def dump(atom) when is_atom(atom) do
    {:ok, Atom.to_string(atom)}
  end

  def compare(perm1, perm2) when is_atom(perm1) and is_atom(perm2) do
    case {to_index(perm1), to_index(perm2)} do
      {first, second} when first > second -> :gt
      {first, second} when first < second -> :lt
      _ -> :eq
    end
  end

  def to_index(value) do
    @allowed_values
    |> Enum.find_index(&(value == &1))
    |> case do
      index when is_integer(index) -> index + 1
      _ -> 0
    end
  end
end
