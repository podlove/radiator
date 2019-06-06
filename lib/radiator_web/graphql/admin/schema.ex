defmodule RadiatorWeb.GraphQL.Admin.Schema do
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
  import_types RadiatorWeb.GraphQL.Admin.Schema.Directory.EpisodeTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.DirectoryTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.StorageTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.MediaTypes
  import_types RadiatorWeb.GraphQL.Admin.Schema.UserTypes

  alias RadiatorWeb.GraphQL.Admin.Resolvers
  alias RadiatorWeb.GraphQL.Admin.Schema.Middleware

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

    @desc "Create a network (Authenticated)"
    field :create_network, type: :network do
      arg :network, non_null(:network_input)
      middleware Middleware.RequireAuthentication

      resolve &Resolvers.Editor.create_network/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Update a network"
    field :update_network, type: :network do
      arg :id, non_null(:id)
      arg :network, non_null(:network_input)

      resolve &Resolvers.Editor.update_network/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Create a podcast"
    field :create_podcast, type: :podcast do
      arg :podcast, non_null(:podcast_input)
      arg :network_id, non_null(:integer)

      resolve &Resolvers.Editor.create_podcast/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Publish podcast"
    field :publish_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.publish_podcast/3
    end

    @desc "Depublish podcast"
    field :depublish_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.depublish_podcast/3
    end

    @desc "Update a podcast"
    field :update_podcast, type: :podcast do
      arg :id, non_null(:id)
      arg :podcast, non_null(:podcast_input)

      resolve &Resolvers.Editor.update_podcast/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Delete a podcast"
    field :delete_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.delete_podcast/3
    end

    # todo: do we still need this?
    field :create_upload, :rad_upload do
      arg :filename, non_null(:string)

      resolve &Resolvers.Storage.create_upload/3
    end

    @desc "Upload audio file to audio object"
    field :upload_audio_file, type: :audio_file do
      arg :audio_id, non_null(:integer)
      arg :file, :upload

      resolve &Resolvers.Storage.upload_audio_file/3
    end

    @desc "Create an episode"
    field :create_episode, type: :episode do
      arg :podcast_id, non_null(:id)
      arg :episode, non_null(:episode_input)

      resolve &Resolvers.Editor.create_episode/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Update an episode"
    field :update_episode, type: :episode do
      arg :id, non_null(:id)
      arg :episode, non_null(:episode_input)

      resolve &Resolvers.Editor.update_episode/3
      middleware Middleware.TranslateChangeset
    end

    @desc "Publish episode"
    field :publish_episode, type: :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.publish_episode/3
    end

    @desc "Depublish episode"
    field :depublish_episode, type: :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.depublish_episode/3
    end

    @desc "Schedule episode"
    field :schedule_episode, type: :episode do
      arg :id, non_null(:id)
      arg :datetime, non_null(:datetime)

      resolve &Resolvers.Editor.schedule_episode/3
    end

    @desc "Delete an episode"
    field :delete_episode, type: :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Editor.delete_episode/3
    end

    @desc "Set chapters for an episode"
    field :set_chapters, type: :audio do
      arg :id, non_null(:id)
      arg :chapters, non_null(:string)
      arg :type, non_null(:string)

      resolve &Resolvers.Editor.set_episode_chapters/3
    end
  end
end
