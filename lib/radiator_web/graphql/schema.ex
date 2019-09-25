defmodule RadiatorWeb.GraphQL.Schema do
  use Absinthe.Schema

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def dataloader() do
    alias Radiator.AudioMeta
    alias Radiator.Directory

    Dataloader.new()
    |> Dataloader.add_source(AudioMeta, AudioMeta.DataloaderProvider.data())
    |> Dataloader.add_source(Directory, Directory.DataloaderProvider.data())
    |> Dataloader.add_source(Directory.Editor, Directory.Editor.DataloaderProvider.data())
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

  enum :published do
    value true
    value false
    value :any
  end

  import_types Absinthe.Type.Custom
  import_types Absinthe.Plug.Types

  import_types RadiatorWeb.GraphQL.Types.SimpleMonth
  import_types RadiatorWeb.GraphQL.Types.SimpleDay
  import_types RadiatorWeb.GraphQL.Common.Types

  import_types RadiatorWeb.GraphQL.Public.Types
  import_types RadiatorWeb.GraphQL.Admin.Types
  import_types RadiatorWeb.GraphQL.FeedInfo.Types

  alias RadiatorWeb.GraphQL.Public
  alias RadiatorWeb.GraphQL.Admin
  alias RadiatorWeb.GraphQL.FeedInfo

  alias RadiatorWeb.GraphQL.Admin.Schema.Middleware

  query do
    # Public queries

    @desc "Get all published podcasts"
    field :published_podcasts, list_of(:published_podcast) do
      resolve &Public.Resolvers.Directory.list_podcasts/3
    end

    @desc "Get one published podcast"
    field :published_podcast, :published_podcast do
      arg :id, non_null(:id)

      resolve &Public.Resolvers.Directory.find_podcast/3
    end

    @desc "Get one published episode"
    field :published_episode, :published_episode do
      arg :id, non_null(:id)

      resolve &Public.Resolvers.Directory.find_episode/3
    end

    @desc "Get one published network"
    field :published_network, :published_network do
      arg :id, non_null(:id)

      resolve &Public.Resolvers.Directory.find_network/3
    end

    @desc "Get all published networks"
    field :published_networks, list_of(:published_network) do
      resolve &Public.Resolvers.Directory.list_networks/3
    end

    # Metalove queries (probably should move to admin eventually to avoid abuse)

    @desc "Get podcast feed info for an url"
    field :feed_info, :feed_info do
      arg :url, non_null(:string)

      resolve &FeedInfo.Resolvers.Metalove.get_feed_info/3
    end

    @desc "Get the content of a feed url"
    field :podcast_feed, :podcast_feed do
      arg :url, non_null(:string)

      resolve &FeedInfo.Resolvers.Metalove.get_feed_content/3
    end

    # Admin queries

    @desc "Get current user"
    field :user, :user do
      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_user/3
    end

    @desc "Find users of this instance"
    field :users, list_of(:public_user) do
      arg :query, non_null(:string)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_users/3
    end

    @desc "Get all possible contribution roles"
    field :contribution_roles, list_of(:contribution_role) do
      resolve &Admin.Resolvers.Editor.list_contribution_roles/3
    end

    @desc "Get all podcasts"
    field :podcasts, list_of(:podcast) do
      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.list_podcasts/3
    end

    @desc "Get one podcast"
    field :podcast, :podcast do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_podcast/3
    end

    @desc "Get one episode"
    field :episode, :episode do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_episode/3
    end

    @desc "Get one network"
    field :network, :network do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_network/3
    end

    @desc "Get all networks"
    field :networks, list_of(:network) do
      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.list_networks/3
    end

    @desc "Get one audio"
    field :audio, :audio do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.find_audio/3
    end
  end

  mutation do
    @desc "Sign up a user"
    field :user_signup, :session do
      arg :username, non_null(:string)
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Public.Resolvers.Session.user_signup/3
    end

    @desc "Request resend of verification email (need auth)"
    field :user_resend_verification_email, :boolean do
      resolve &Admin.Resolvers.User.resend_verification_email/3
    end

    @desc "Request an authenticated session"
    field :authenticated_session, :session do
      arg :username_or_email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Public.Resolvers.Session.get_authenticated_session/3
    end

    @desc "Prolong an authenticated session"
    field :prolong_session, :session do
      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Session.prolong_authenticated_session/3
    end
  end
end
