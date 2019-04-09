defmodule Radiator.Auth.Ecto.UserStatusType do
  @behaviour Ecto.Type

  @allowed_values [:unverified, :active, :suspended]

  def allowed_values do
    @allowed_values
  end

  def type, do: :binary

  def cast(binary) when is_binary(binary), do: cast(String.to_existing_atom(binary))

  def cast(atom) when is_atom(atom) do
    if atom in @allowed_values do
      {:ok, atom}
    else
      :error
    end
  end

  def load(data) when is_binary(data) do
    {:ok, String.to_existing_atom(data)}
  end

  def dump(atom) when is_atom(atom) do
    {:ok, Atom.to_string(atom)}
  end
end
