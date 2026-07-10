defmodule Radiator.Podcasts.Episode.Scheduling.Validations.OwnerOnly do
  @moduledoc """
  Validates that the `user_id` argument matches the scheduling's `owner_user_id`.

  Accepts an optional `message` keyword to customise the error per action.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, opts, _context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)
    owner_id = Ash.Changeset.get_attribute(changeset, :owner_user_id)
    message = Keyword.get(opts, :message, "Only the owner can perform this action")

    if user_id == owner_id do
      :ok
    else
      {:error, message: message}
    end
  end
end
