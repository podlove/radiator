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
  def create_changeset(file, attrs) do
    file
    |> cast(attrs, [:size, :name, :extension, :mime_type])
  end

  @doc false
  def upload_changeset(file, attrs) do
    file
    |> cast_attachments(attrs, [:file], allow_paths: true, allow_urls: true)
  end

  def extract_meta(%Plug.Upload{path: path}) do
    extract_meta(path)
  end

  def extract_meta(path) when is_binary(path) do
    {:ok, %{size: size}} = File.lstat(path)

    %{
      size: size,
      extension: path |> Path.extname() |> String.trim_leading("."),
      name: Path.basename(path),
      mime_type: MIME.from_path(path)
    }
  end
end
