defmodule Radiator.Auth.Ecto.UserStatusType do
  use Ecto.Type
  alias Ecto.Type

  use Radiator.Constants

  @allowed_values @auth_user_status_values

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
end
