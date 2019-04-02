defmodule RadiatorWeb.Schema.Directory.EpisodeTypes do
  use Absinthe.Schema.Notation

  @desc "A chapter in an episode"
  object :chapter do
    field :time, :integer
    field :title, :string
    field :url, :string
    field :image, :string
  end
end
