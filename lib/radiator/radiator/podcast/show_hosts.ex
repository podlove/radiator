defmodule Radiator.Podcast.ShowHosts do
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Podcast.Show
  alias Radiator.Accounts.User

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
