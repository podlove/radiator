defmodule Radiator.Directory.UserProfile do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Auth.User
  alias Radiator.Media

  schema "user_profiles" do
    field :display_name, :string
    field :image, Media.UserAvatar.Type

    belongs_to :user, User

    timestamps()
  end

  def changeset(profile = %__MODULE__{}, attrs) do
    profile
    |> cast(attrs, [:display_name])
    |> validate_required([:display_name])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%__MODULE__{} = subject) do
    Media.UserAvatar.url({subject.image, subject})
  end
end
