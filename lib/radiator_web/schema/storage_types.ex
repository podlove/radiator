defmodule RadiatorWeb.Schema.StorageTypes do
  use Absinthe.Schema.Notation

  @desc "Intermediary object providing an URL to upload against"
  object :rad_upload do
    field :upload_url, :string
  end

  @desc "Audio File"
  object :audio_file do
    field :mime_type, :string
    field :byte_length, :integer
    field :title, :string
  end
end
