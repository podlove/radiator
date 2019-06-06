defmodule RadiatorWeb.GraphQL.Public.Schema.DirectoryTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias RadiatorWeb.GraphQL.Public.Resolvers

  @desc "A network"
  object :network do
    field :id, non_null(:id)
    field :title, :string
    field :slug, :string

    field :image, :string do
      resolve &Resolvers.Directory.get_image_url/3
    end

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

    field :image, :string do
      resolve &Resolvers.Directory.get_image_url/3
    end

    field :language, :string
    field :last_built_at, :datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :datetime
    field :subtitle, :string
    field :slug, :string

    field :episodes, list_of(:episode) do
      arg :page, type: :integer, default_value: 1
      arg :items_per_page, type: :integer, default_value: 10
      arg :order_by, type: :episode_order, default_value: :published_at
      arg :order, type: :sort_order, default_value: :desc

      resolve dataloader(Radiator.Directory, :episodes)
    end

    field :episodes_count, :integer do
      resolve &Resolvers.Directory.get_episodes_count/3
    end
  end

  @desc "An episode in a podcast"
  object :episode do
    field :id, non_null(:id)
    field :content, :string
    field :description, :string
    field :duration, :string
    field :guid, :string

    field :image, :string do
      resolve &Resolvers.Directory.get_image_url/3
    end

    field :number, :integer
    field :published_at, :datetime
    field :subtitle, :string
    field :title, :string
    field :slug, :string

    field :podcast, :podcast do
      resolve &Resolvers.Directory.find_podcast/3
    end

    field :enclosure, :enclosure do
      resolve &Resolvers.Directory.get_enclosure/3
    end

    field :chapters, list_of(:chapter) do
      arg :order, type: :sort_order, default_value: :asc

      resolve dataloader(Radiator.AudioMeta, :chapters)
    end
  end
end
