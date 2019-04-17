defmodule Radiator.Directory.Editor.EditorHelpers do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Radiator.Repo

  def get_permission_p(user, subject) do
    query =
      from perm in Ecto.assoc(subject, :permissions),
        where: perm.user_id == ^user.id

    Repo.one(query)
  end
end
