defmodule Radiator.Storage.FileSlot do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Storage

  schema "file_slots" do
    field :slot, :string
    field :subject_type, :string
    field :subject_id, :integer

    belongs_to :file, Storage.File

    timestamps()
  end

  @valid_slots ~w(audio_mp3 audio_m4a audio_ogg audio_opus)
  @valid_subjects ~w(audio)

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:slot, :subject_type, :subject_id])
    |> validate_inclusion(:slot, @valid_slots)
    |> validate_inclusion(:subject_type, @valid_subjects)
  end
end
