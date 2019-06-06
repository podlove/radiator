defmodule Radiator.Media.AudioFile do
  use Ecto.Schema

  use Arc.Definition
  use Arc.Ecto.Definition

  import Ecto.Changeset
  import Arc.Ecto.Changeset

  alias Radiator.Media
  alias Radiator.Directory.Audio

  schema "audio_files" do
    field :file, Media.AudioFile.Type
    field :title, :string
    field :mime_type, :string
    field :byte_length, :integer

    belongs_to :audio, Audio

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :mime_type, :byte_length])
    |> cast_attachments(attrs, [:file], allow_paths: true, allow_urls: true)
  end

  def public_url(audio) do
    tracking_url(audio)
  end

  def tracking_url(audio = %__MODULE__{}) do
    RadiatorWeb.Router.Helpers.tracking_url(RadiatorWeb.Endpoint, :show, audio.id)
  end

  # arc override
  def storage_dir(_version, {_file, audio}) do
    "audio/#{audio.id}"
  end

  # arc override
  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
