defmodule Radiator.Podcasts.Episode.Scheduling.Validations.UserIsActor do
  @moduledoc "Validates that the `user_id` argument equals the current actor's id."
  use Ash.Resource.Validation

  alias Radiator.Accounts.User

  @error_message "user does not match current actor"

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)

    case context.actor do
      %User{id: ^user_id} -> :ok
      _ -> {:error, field: :user_id, message: @error_message}
    end
  end
end
