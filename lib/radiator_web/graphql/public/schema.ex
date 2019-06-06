defmodule RadiatorWeb.GraphQL.Public.Schema do
  use Absinthe.Schema

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader() do
    alias Radiator.AudioMeta
    alias Radiator.Directory

    Dataloader.new()
    |> Dataloader.add_source(AudioMeta, AudioMeta.data())
    |> Dataloader.add_source(Directory, Directory.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  enum :sort_order do
    value :asc
    value :desc
  end

  enum :episode_order do
    value :published_at
    value :title
  end

  import_types Absinthe.Type.Custom
  import_types Absinthe.Plug.Types
  import_types RadiatorWeb.GraphQL.Public.Schema.Directory.EpisodeTypes
  import_types RadiatorWeb.GraphQL.Public.Schema.DirectoryTypes
  import_types RadiatorWeb.GraphQL.Public.Schema.StorageTypes
  import_types RadiatorWeb.GraphQL.Public.Schema.MediaTypes
  import_types RadiatorWeb.GraphQL.Public.Schema.UserTypes

  alias RadiatorWeb.GraphQL.Public.Resolvers

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

    @desc "Get one network"
    field :network, :network do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.find_network/3
    end

    @desc "Get all networks"
    field :networks, list_of(:network) do
      resolve &Resolvers.Directory.list_networks/3
    end
  end

  mutation do
    @desc "Request an authenticated session"
    field :authenticated_session, :session do
      arg :username_or_email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Resolvers.Session.get_authenticated_session/3
    end
  end
end
