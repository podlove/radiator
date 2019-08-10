defmodule Radiator.Media.AudioFile do
  use Ecto.Schema

  use Arc.Definition
  use Arc.Ecto.Definition

  import Ecto.Changeset
  import Arc.Ecto.Changeset

  alias Radiator.Media
  alias Radiator.Directory.Audio

  schema "audio_files" do
    field(:file, Media.AudioFile.Type)
    field(:title, :string)
    field(:mime_type, :string)
    field(:byte_length, :integer)

    belongs_to(:audio, Audio)

    timestamps()
  end

  @doc false
  def changeset(audio_file = %__MODULE__{}, attrs) do
    audio_file
    |> cast(attrs, [:title, :mime_type, :byte_length, :audio_id])
    #    |> cast_or_constraint_assoc(:audio)
    |> cast_attachments(attrs, [:file], allow_paths: true, allow_urls: true)

    # todo: determine byte length and mime type on file change, don't take them as attrs
  end

  # fixme: auidofile.upload geht bei dom nicht mehr
  # not sure if this is the best way
  # via https://elixirforum.com/t/ecto-validating-belongs-to-association-is-not-nil/2665/13
  defp cast_or_constraint_assoc(changeset, name) do
    {:assoc, %{owner_key: key}} = changeset.types[name]

    if changeset.changes[key] do
      assoc_constraint(changeset, name)
    else
      cast_assoc(changeset, name, required: true)
    end
  end

  def public_url(audio_file = %__MODULE__{}) do
    tracking_url(audio_file)
  end

  def tracking_url(audio_file = %__MODULE__{}) do
    RadiatorWeb.Router.Helpers.tracking_url(RadiatorWeb.Endpoint, :show, audio_file.id)
  end

  def internal_url(audio_file = %__MODULE__{}) do
    __MODULE__.url({audio_file.file, audio_file})
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
