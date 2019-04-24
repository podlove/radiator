defmodule Radiator.Directory.Editor.EditorHelpers do
  @moduledoc false
  # Internal helpers

  import Ecto.Query, warn: false

  alias Radiator.Repo

  def get_permission(user, subject) do
    query =
      from perm in Ecto.assoc(subject, :permissions),
        where: perm.user_id == ^user.id

    Repo.one(query)
  end
end
