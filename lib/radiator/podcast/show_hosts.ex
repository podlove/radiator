defmodule Radiator.Podcast.ShowHosts do
  @moduledoc """
    Represents the show_hosts model.
    Used for many-to-many relationship between shows and users.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Accounts.User
  alias Radiator.Podcast.Show

  schema "show_hosts" do
    belongs_to :show, Show
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(show_hosts, attrs) do
    show_hosts
    |> cast(attrs, [:show_id, :user_id])
    |> validate_required([:show_id, :user_id])
  end
end
