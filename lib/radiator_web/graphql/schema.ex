defmodule RadiatorWeb.GraphQL.Schema do
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

  enum :published do
    value true
    value false
    value :any
  end

  import_types Absinthe.Type.Custom
  import_types Absinthe.Plug.Types

  import_types RadiatorWeb.GraphQL.Common.Types

  import_types RadiatorWeb.GraphQL.Public.Types
  import_types RadiatorWeb.GraphQL.Admin.Types

  alias RadiatorWeb.GraphQL.Public
  alias RadiatorWeb.GraphQL.Admin

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

    # Admin queries

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

    @desc "Create a network (Authenticated)"
    field :create_network, type: :network do
      arg :network, non_null(:network_input)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.create_network/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Update a network"
    field :update_network, type: :network do
      arg :id, non_null(:id)
      arg :network, non_null(:network_input)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.update_network/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Create a podcast"
    field :create_podcast, type: :podcast do
      arg :podcast, non_null(:podcast_input)
      arg :network_id, non_null(:integer)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.create_podcast/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Publish podcast"
    field :publish_podcast, type: :podcast do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.publish_podcast/3
    end

    @desc "Depublish podcast"
    field :depublish_podcast, type: :podcast do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.depublish_podcast/3
    end

    @desc "Update a podcast"
    field :update_podcast, type: :podcast do
      arg :id, non_null(:id)
      arg :podcast, non_null(:podcast_input)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.update_podcast/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Delete a podcast"
    field :delete_podcast, type: :podcast do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.delete_podcast/3
    end

    @desc "Upload audio file to audio object"
    field :upload_audio_file, type: :audio_file do
      arg :audio_id, non_null(:integer)
      arg :file, :upload

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Storage.upload_audio_file/3
    end

    @desc "Create an episode"
    field :create_episode, type: :episode do
      arg :podcast_id, non_null(:id)
      arg :episode, non_null(:episode_input)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.create_episode/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Update an episode"
    field :update_episode, type: :episode do
      arg :id, non_null(:id)
      arg :episode, non_null(:episode_input)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.update_episode/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Publish episode"
    field :publish_episode, type: :episode do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.publish_episode/3
    end

    @desc "Depublish episode"
    field :depublish_episode, type: :episode do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.depublish_episode/3
    end

    @desc "Schedule episode"
    field :schedule_episode, type: :episode do
      arg :id, non_null(:id)
      arg :datetime, non_null(:datetime)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.schedule_episode/3
    end

    @desc "Delete an episode"
    field :delete_episode, type: :episode do
      arg :id, non_null(:id)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.delete_episode/3
    end

    @desc "Set chapters for an episode"
    field :set_chapters, type: :audio do
      arg :id, non_null(:id)
      arg :chapters, non_null(:string)
      arg :type, non_null(:string)

      middleware Middleware.RequireAuthentication
      resolve &Admin.Resolvers.Editor.set_episode_chapters/3
    end
  end
end
