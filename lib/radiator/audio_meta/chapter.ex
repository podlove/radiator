defmodule Radiator.AudioMeta.Chapter do
  use Ecto.Schema
  import Ecto.Changeset
  import Arc.Ecto.Changeset

  import Ecto.Query, warn: false

  alias Radiator.Directory.Audio
  alias Radiator.Media

  @primary_key false
  schema "chapters" do
    field :start, :integer, primary_key: true
    field :title, :string
    field :link, :string
    field :image, Media.ChapterImage.Type

    belongs_to :audio, Audio, primary_key: true
  end

  @doc false
  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [
      :start,
      :title,
      :link
    ])
    |> validate_required([:start])
    |> maybe_delete_existing_attachments(attrs)
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
  end

  def maybe_delete_existing_attachments(changeset, %{image: _image}) do
    Radiator.AudioMeta.delete_chapter_image(changeset.data)
    changeset
  end

  def maybe_delete_existing_attachments(changeset, _attrs), do: changeset

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%__MODULE__{} = subject) do
    Media.ChapterImage.url({subject.image, subject})
  end

  def ordered_query do
    from c in __MODULE__, order_by: c.start
  end
end
