defmodule Radiator.Storage.File do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "files" do
    field :file, Radiator.Media.File.Type
    field :size, :integer
    field :name, :string
    field :extension, :string
    field :mime_type, :string

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:size, :name, :extension, :mime_type])
    |> cast_attachments(attrs, [:file], allow_paths: true, allow_urls: true)
  end

  # todo: move to storage context
  # todo: auto-detect name, size, ext, mime type
  # gist: create without file first because we need the id for storage
  def create(path) do
    %__MODULE__{}
    |> Radiator.Repo.insert()
    |> elem(1)
    |> __MODULE__.changeset(%{
      file: path
    })
    |> Radiator.Repo.update()
  end
end
