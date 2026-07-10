defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ParticipantOnly do
  @moduledoc """
  Validates that the `user_id` argument belongs to a participant of the
  scheduling's episode (the single source of truth for eligible voters).

  This performs a database lookup and is therefore intentionally registered
  after cheaper, in-memory validations on the same action.

  Accepts an optional `message` keyword to customise the error per action.
  """
  use Ash.Resource.Validation

  require Ash.Query

  alias Radiator.Podcasts.EpisodeParticipant

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, opts, _context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)
    episode_id = Ash.Changeset.get_attribute(changeset, :episode_id)
    message = Keyword.get(opts, :message, "Only participants can perform this action")

    if participant?(episode_id, user_id) do
      :ok
    else
      {:error, message: message}
    end
  end

  defp participant?(episode_id, user_id) when is_binary(episode_id) and is_binary(user_id) do
    EpisodeParticipant
    |> Ash.Query.filter(episode_id == ^episode_id and user_id == ^user_id)
    |> Ash.read_one(authorize?: false)
    |> case do
      {:ok, %EpisodeParticipant{}} -> true
      _ -> false
    end
  end

  defp participant?(_episode_id, _user_id), do: false
end
