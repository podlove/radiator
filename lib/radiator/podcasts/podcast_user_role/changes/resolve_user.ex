defmodule Radiator.Podcasts.PodcastUserRole.Changes.ResolveUser do
  @moduledoc """
  Turns the `email` argument into a `user_id`, creating the user if nobody
  has signed up with that address yet. Without an email the caller has to
  supply `user_id` itself.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :email) do
      nil ->
        changeset

      email ->
        Ash.Changeset.before_action(changeset, &relate_user(&1, email))
    end
  end

  defp relate_user(changeset, email) do
    case find_or_create_user(email) do
      {:ok, user} ->
        if member?(Ash.Changeset.get_attribute(changeset, :podcast_id), user.id) do
          Ash.Changeset.add_error(changeset, field: :email, message: "is already a member")
        else
          Ash.Changeset.force_change_attribute(changeset, :user_id, user.id)
        end

      {:error, error} ->
        Ash.Changeset.add_error(changeset, field: :email, message: error_message(error))
    end
  end

  defp member?(nil, _user_id), do: false

  defp member?(podcast_id, user_id) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast_id and user_id == ^user_id)
    |> Ash.exists?(authorize?: false)
  end

  defp find_or_create_user(email) do
    User
    |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
    |> Ash.read_one()
    |> case do
      {:ok, nil} -> Ash.create(User, %{email: email}, action: :create_invited, authorize?: false)
      other -> other
    end
  end

  defp error_message(%{errors: [%{message: message} | _]}) when is_binary(message), do: message
  defp error_message(_error), do: "is invalid"
end
