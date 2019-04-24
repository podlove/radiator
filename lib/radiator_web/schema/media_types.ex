defmodule RadiatorWeb.Schema.MediaTypes do
  use Absinthe.Schema.Notation

  @desc "An audio enclosure"
  object :enclosure do
    field :url, :string
    field :type, :string
    field :length, :integer
  end
end
