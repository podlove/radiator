defmodule RadiatorWeb.Schema.StorageTypes do
  use Absinthe.Schema.Notation

  @desc "Intermediary object providing an URL to upload against"
  object :upload do
    field :upload_url, :string
  end
end
