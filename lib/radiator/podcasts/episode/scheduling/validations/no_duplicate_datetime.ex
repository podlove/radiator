defmodule Radiator.Podcasts.Episode.Scheduling.Validations.NoDuplicateDatetime do
  @moduledoc "A date can only be proposed once per scheduling."

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    datetime = changeset |> Ash.Changeset.get_argument(:datetime) |> truncate()
    proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

    if Enum.any?(proposals, &(truncate(&1.datetime) == datetime)) do
      {:error, field: :datetime, message: "has already been proposed"}
    else
      :ok
    end
  end

  defp truncate(%DateTime{} = datetime), do: DateTime.truncate(datetime, :second)
  defp truncate(other), do: other
end
