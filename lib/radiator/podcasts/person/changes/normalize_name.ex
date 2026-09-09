defmodule Radiator.Podcasts.Person.Changes.NormalizeName do
  @moduledoc """
  Derives `normalized_name` from `name`, so the two can never disagree.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Person

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :name) do
      nil ->
        changeset

      name ->
        Ash.Changeset.force_change_attribute(changeset, :normalized_name, Person.normalize(name))
    end
  end
end
