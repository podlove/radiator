defmodule Radiator.EventStore.EventData do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Accounts.User

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "event_data" do
    field :data, :map, default: %{}
    field :event_type, :string

    belongs_to :user, User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:uuid, :event_type, :data])
    |> validate_required([:uuid, :event_type])
  end
end
