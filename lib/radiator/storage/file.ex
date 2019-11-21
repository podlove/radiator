defmodule Radiator.Storage.File do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Directory.Network

  # FIXME: currently files have no owner/permission management
  # - at least keep track of who uploaded it
  # - simplest permission case: always scope to network and only
  #   who can manage a network can upload files...? manage files?
  #   read files? Anyone in network can read, maybe, no matter what
  #   perms he/she has because assuming most files are public anyway,
  #   setting detailed permissions per file sounds like over engineering
  # - is network too high? no it's not. podcast is to low because then
  #   there is no place to get files for audio_publications
  # - it might be useful to "loosely" assign files to subjects without
  #   a fixed slot in mind, but that can be done with slot model atm,
  #   if we allow leaving the slot blank
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "files" do
    field :file, Radiator.Media.File.Type
    field :size, :integer
    field :name, :string
    field :extension, :string
    field :mime_type, :string

    belongs_to :network, Network

    has_many :file_slots, Radiator.Storage.FileSlot

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
