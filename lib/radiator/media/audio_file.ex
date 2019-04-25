defmodule Radiator.Media.AudioFile do
  use Ecto.Schema
  use Arc.Ecto.Schema

  use Arc.Definition
  use Arc.Ecto.Definition

  import Ecto.Changeset

  schema "audio_files" do
    field :file, Radiator.Media.AudioFile.Type
    field :title, :string
    field :mime_type, :string
    field :byte_length, :integer

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :mime_type, :byte_length])
    |> cast_attachments(attrs, [:file])
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
