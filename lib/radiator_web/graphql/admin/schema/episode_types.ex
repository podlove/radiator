defmodule RadiatorWeb.GraphQL.Admin.Schema.Directory.EpisodeTypes do
  use Absinthe.Schema.Notation

  @desc "A chapter in an episode"
  object :chapter do
    field :start, :integer
    field :title, :string
    field :link, :string
    field :image, :string
  end
end
