defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for modifying data.
  """

  import Ecto.Query, warn: false

  alias Radiator.Auth

  alias Radiator.Repo
  alias Radiator.Directory
  alias Directory.{Network, Podcast, Episode}

  alias Directory.Editor.EditorHelpers

  def list_networks do
  end

  # Permission

  def get_permission(user = %Auth.User{}, subject = %Network{}),
    do: get_permission_p(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Podcast{}),
    do: get_permission_p(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Episode{}),
    do: get_permission_p(user, subject)

  defp get_permission_p(user, subject) do
    case EditorHelpers.get_permission_p(user, subject) do
      nil -> nil
      perm -> perm.permission
    end
  end
end
