defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ParticipantOnly do
  @moduledoc """
  Validates that the `user_id` argument belongs to a scheduling participant.

  Accepts an optional `message` keyword to customise the error per action.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, opts, _context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)
    participant_ids = Ash.Changeset.get_attribute(changeset, :participant_user_ids) || []
    message = Keyword.get(opts, :message, "Only participants can perform this action")

    if user_id in participant_ids do
      :ok
    else
      {:error, message: message}
    end
  end
end
