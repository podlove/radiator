defmodule Radiator.Podcasts.Episode.Scheduling.Validations.PersonaBelongsToActor do
  @moduledoc """
  Validates that the `persona_id` argument refers to a persona linked to the
  current actor (user).

  This validation performs a database lookup and is therefore intentionally
  registered after cheaper, in-memory validations on the same action.

  Fails when any of the following is true:
  - There is no actor in context
  - The actor is not a `Radiator.Accounts.User`
  - The persona does not exist
  - The persona's `user_id` is `nil` (no linked user)
  - The persona's `user_id` does not match `actor.id`
  """
  use Ash.Resource.Validation

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.People.Persona

  @error_message "persona does not belong to current user"

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, context) do
    persona_id = Ash.Changeset.get_argument(changeset, :persona_id)

    case context.actor do
      %User{id: actor_id} -> validate_ownership(persona_id, actor_id)
      _ -> {:error, field: :persona_id, message: @error_message}
    end
  end

  defp validate_ownership(persona_id, actor_id) do
    Persona
    |> Ash.Query.filter(id == ^persona_id and user_id == ^actor_id)
    |> Ash.read_one(authorize?: false)
    |> case do
      {:ok, %Persona{}} -> :ok
      _ -> {:error, field: :persona_id, message: @error_message}
    end
  end
end
