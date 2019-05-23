defmodule RadiatorWeb.GraphQL.Admin.Schema do
  use Absinthe.Schema

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader() do
    alias Radiator.EpisodeMeta
    alias Radiator.Directory

    Dataloader.new()
    |> Dataloader.add_source(EpisodeMeta, EpisodeMeta.data())
    |> Dataloader.add_source(Directory, Directory.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  enum :sort_order do
    value :asc
    value :desc
  end

  enum :published do
    value true
    value false
    value :any
  end

  import_types Absinthe.Type.Custom
  import_types Absinthe.Plug.Types
  import_types RadiatorWeb.GraphQL.Admin.Schema.Directory.EpisodeTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.DirectoryTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.StorageTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.MediaTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.UserTypes

  alias RadiatorWeb.GraphQL.Admin.Resolvers

  query do
    @desc "Get all podcasts"
    field :podcasts, list_of(:podcast) do
      resolve &Resolvers.Editor.list_podcasts/3
    end

    @desc "Get one podcast"
    field :podcast, :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.find_podcast/3
    end

    @desc "Get one episode"
    field :episode, :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.find_episode/3
    end

    @desc "Get one network"
    field :network, :network do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.find_network/3
    end

    @desc "Get all networks"
    field :networks, list_of(:network) do
      resolve &Resolvers.Editor.list_networks/3
    end
  end

  mutation do
    @desc "Prolong an authenticated session"
    field :prolong_session, :session do
      arg :username_or_email, non_null(:string)
      resolve &Resolvers.Session.prolong_authenticated_session/3
    end
  end
end
