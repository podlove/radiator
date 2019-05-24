defmodule RadiatorWeb.GraphQL.Admin.Schema.DirectoryTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias RadiatorWeb.GraphQL.Admin.Resolvers

  @desc "A network"
  object :network do
    field :id, non_null(:id)
    field :title, :string
    field :slug, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :podcasts, list_of(:podcast) do
      resolve &Resolvers.Editor.list_podcasts/3
    end
  end

  @desc "The input for a network"
  input_object :network_input do
    field :title, non_null(:string)
    field :image, :upload
  end

  @desc "A podcast"
  object :podcast do
    field :id, non_null(:id)
    field :title, :string
    field :author, :string
    field :description, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :language, :string
    field :last_built_at, :datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :datetime
    field :subtitle, :string
    field :slug, :string

    field :is_published, :boolean do
      resolve &Resolvers.Editor.is_published/3
    end

    field :episodes, list_of(:episode) do
      arg :published, type: :published, default_value: :any
      arg :page, type: :integer, default_value: 1
      arg :items_per_page, type: :integer, default_value: 10

      resolve dataloader(Radiator.Directory, :episodes)
    end

    field :episodes_count, :integer do
      resolve &Resolvers.Editor.get_episodes_count/3
    end
  end

  @desc "The input for a podcast"
  input_object :podcast_input do
    field :title, non_null(:string)
    field :subtitle, :string
    field :description, :string
    field :image, :upload
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
    field :guid, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :number, :integer
    field :published_at, :datetime
    field :subtitle, :string
    field :title, :string
    field :slug, :string

    field :is_published, :boolean do
      resolve &Resolvers.Editor.is_published/3
    end

    field :podcast, :podcast do
      resolve &Resolvers.Editor.find_podcast/3
    end

    field :enclosure, :enclosure do
      resolve &Resolvers.Editor.get_enclosure/3
    end

    field :chapters, list_of(:chapter) do
      arg :order, type: :sort_order, default_value: :asc

      resolve dataloader(Radiator.EpisodeMeta, :chapters)
    end
  end

  @desc "The input for an episode in a podcast"
  input_object :episode_input do
    field :title, non_null(:string)
    field :subtitle, :string
    field :description, :string
    field :content, :string
    field :image, :upload
    field :number, :integer
  end
end
