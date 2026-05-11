defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore do
  @moduledoc "Validates that the score argument is an integer between 1 and 5."
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    score = Ash.Changeset.get_argument(changeset, :score)

    if score in 1..5 do
      :ok
    else
      {:error, field: :score, message: "Score must be between 1 and 5"}
    end
  end
end
