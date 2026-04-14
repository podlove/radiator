defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ParticipantOnly do
  @moduledoc """
  Validates that the `persona_id` argument belongs to a scheduling participant.

  Accepts an optional `message` keyword to customise the error per action.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, opts, _context) do
    persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
    participant_ids = Ash.Changeset.get_attribute(changeset, :participant_persona_ids) || []
    message = Keyword.get(opts, :message, "Only participants can perform this action")

    if persona_id in participant_ids do
      :ok
    else
      {:error, message: message}
    end
  end
end
