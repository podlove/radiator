defmodule RadiatorWeb.GraphQL.Public.Schema.StorageTypes do
  use Absinthe.Schema.Notation

  @desc "Audio File"
  object :audio_file do
    field :mime_type, :string
    field :byte_length, :integer
    field :title, :string
  end
end
