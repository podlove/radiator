defmodule Radiator.Tracking.Download do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Directory.{Network, Podcast, Episode}

  schema "downloads" do
    field :request_id, :string
    field :accessed_at, :utc_datetime
    field :clean, :boolean, default: true
    field :httprange, :string
    field :context, :string

    field :user_agent, :string
    field :user_agent_bot, :boolean, default: false
    field :user_agent_client_name, :string
    field :user_agent_client_type, :string
    field :user_agent_device_model, :string
    field :user_agent_device_type, :string
    field :user_agent_os_name, :string

    belongs_to :network, Network
    belongs_to :podcast, Podcast
    belongs_to :episode, Episode

    timestamps()
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [
      :request_id,
      :accessed_at,
      :context,
      :httprange,
      :clean,
      :user_agent,
      :user_agent_bot,
      :user_agent_client_name,
      :user_agent_client_type,
      :user_agent_os_name,
      :user_agent_device_type,
      :user_agent_device_model
    ])
    |> validate_required([
      :request_id,
      :accessed_at,
      :clean
    ])
  end
end
