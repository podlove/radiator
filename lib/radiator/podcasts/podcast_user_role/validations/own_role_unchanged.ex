defmodule Radiator.Podcasts.PodcastUserRole.Validations.OwnRoleUnchanged do
  @moduledoc """
  Nobody may change the role of their own membership.
  """

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, %{actor: %{id: actor_id}}) do
    if changeset.data.user_id == actor_id and
         Ash.Changeset.get_attribute(changeset, :role) != changeset.data.role do
      {:error, field: :role, message: "cannot be changed for your own membership"}
    else
      :ok
    end
  end

  def validate(_changeset, _opts, _context), do: :ok
end
