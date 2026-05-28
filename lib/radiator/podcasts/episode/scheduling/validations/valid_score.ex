defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore do
  @moduledoc "Validates that the score argument is one of `-1`, `0`, or `1`."
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    score = Ash.Changeset.get_argument(changeset, :score)

    if score in [-1, 0, 1] do
      :ok
    else
      {:error, field: :score, message: "Score must be -1, 0 or 1"}
    end
  end
end
