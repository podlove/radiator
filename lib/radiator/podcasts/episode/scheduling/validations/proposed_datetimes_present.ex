defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ProposedDatetimesPresent do
  @moduledoc "Validates that the `proposed_datetimes` argument contains at least one entry."
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    proposed_datetimes = Ash.Changeset.get_argument(changeset, :proposed_datetimes) || []

    if Enum.empty?(proposed_datetimes) do
      {:error, field: :proposed_datetimes, message: "At least one proposed datetime is required"}
    else
      :ok
    end
  end
end
