defmodule Radiator.Tracking.Download do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    AudioPublication,
    Audio
  }

  alias Radiator.Media.AudioFile

  schema "downloads" do
    field :request_id, :string
    field :accessed_at, :utc_datetime
    field :httprange, :string
    field :context, :string

    field :user_agent, :string
    field :client_name, :string
    field :client_type, :string
    field :device_model, :string
    field :device_type, :string
    field :os_name, :string

    field :hours_since_published, :integer

    belongs_to :network, Network
    belongs_to :podcast, Podcast
    belongs_to :episode, Episode
    belongs_to :audio_publication, AudioPublication
    belongs_to :audio, Audio
    belongs_to :file, AudioFile

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
      :user_agent,
      :client_name,
      :client_type,
      :os_name,
      :device_type,
      :device_model,
      :hours_since_published
    ])
    |> validate_required([
      :request_id,
      :accessed_at
    ])
  end
end
