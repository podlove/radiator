defmodule RadiatorWeb.Schema.DirectoryTypes do
  use Absinthe.Schema.Notation

  alias RadiatorWeb.Resolvers

  @desc "A podcast"
  object :podcast do
    field :id, :id
    field :title, :string
    field :author, :string
    field :description, :string
    field :image, :string
    field :language, :string
    field :last_built_at, :datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :datetime
    field :subtitle, :string

    field :is_published, :boolean do
      resolve &Resolvers.Directory.is_published/3
    end

    field :episodes, list_of(:episode) do
      resolve &Resolvers.Directory.list_episodes/3
    end
  end

  @desc "An episode in a podcast"
  object :episode do
    field :id, :id
    field :content, :string
    field :description, :string
    field :duration, :string
    field :enclosure_length, :integer
    field :enclosure_type, :string
    field :enclosure_url, :string
    field :guid, :string
    field :image, :string
    field :number, :integer
    field :published_at, :datetime
    field :subtitle, :string
    field :title, :string

    field :podcast, :podcast do
      resolve &Resolvers.Directory.find_podcast/3
    end
  end
end
