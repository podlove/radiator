defmodule RadiatorWeb.Schema.DirectoryTypes do
  use Absinthe.Schema.Notation

  alias RadiatorWeb.Resolvers

  @desc "A network"
  object :network do
    field :id, non_null(:id)
    field :title, :string
    field :image, :string

    field :podcasts, list_of(:podcast) do
      resolve &Resolvers.Directory.list_podcasts/3
    end
  end

  @desc "A podcast"
  object :podcast do
    field :id, non_null(:id)
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

  @desc "The input for a podcast"
  input_object :podcast_input do
    field :title, non_null(:string)
    field :subtitle, :string
    field :description, :string
    field :image, :string
    field :language, :string
    field :owner_email, :string
    field :owner_name, :string
  end

  @desc "An episode in a podcast"
  object :episode do
    field :id, non_null(:id)
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

  @desc "The input for an episode in a podcast"
  input_object :episode_input do
    field :title, non_null(:string)
    field :subtitle, :string
    field :description, :string
    field :content, :string
    field :image, :string
    field :number, :integer
  end
end
