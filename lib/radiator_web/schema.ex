defmodule RadiatorWeb.Schema do
  use Absinthe.Schema

  import_types RadiatorWeb.Schema.DirectoryTypes
  import_types RadiatorWeb.Schema.StorageTypes

  alias RadiatorWeb.Resolvers

  scalar :datetime do
    description "Date & Time (in ISO8601 Extended format)"
    parse &Timex.parse!(&1, "{ISO:Extended}")
    serialize &Timex.format!(&1, "{ISO:Extended}")
  end

  query do
    @desc "Get all podcasts"
    field :podcasts, list_of(:podcast) do
      resolve &Resolvers.Directory.list_podcasts/3
    end

    @desc "Get one podcast"
    field :podcast, :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.find_podcast/3
    end

    @desc "Get one episode"
    field :episode, :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.find_episode/3
    end

    @desc "Get all episodes"
    field :episodes, list_of(:episode) do
      resolve &Resolvers.Directory.list_episodes/3
    end
  end

  mutation do
    @desc "Create a podcast"
    field :create_podcast, type: :podcast do
      arg :title, non_null(:string)
      arg :subtitle, :string
      arg :description, :string
      arg :image, :string
      arg :language, :string
      arg :owner_email, :string
      arg :owner_name, :string

      resolve &Resolvers.Directory.create_podcast/3
    end

    @desc "Publish podcast"
    field :publish_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.publish_podcast/3
    end

    @desc "Depublish podcast"
    field :depublish_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.depublish_podcast/3
    end

    @desc "Update a podcast"
    field :update_podcast, type: :podcast do
      arg :id, non_null(:id)
      arg :title, :string
      arg :subtitle, :string
      arg :description, :string
      arg :image, :string
      arg :language, :string
      arg :owner_email, :string
      arg :owner_name, :string

      resolve &Resolvers.Directory.update_podcast/3
    end

    @desc "Delete a podcast"
    field :delete_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.delete_podcast/3
    end

    field :create_upload, :upload do
      arg :filename, non_null(:string)

      resolve &Resolvers.Storage.create_upload/3
    end
  end
end
