defmodule RadiatorWeb.Schema do
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
  import_types RadiatorWeb.Schema.Directory.EpisodeTypes
  import_types RadiatorWeb.Schema.DirectoryTypes
  import_types RadiatorWeb.Schema.StorageTypes
  import_types RadiatorWeb.Schema.MediaTypes

  alias RadiatorWeb.Resolvers

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
    @desc "Create a network"
    field :create_network, type: :network do
      arg :network, non_null(:network_input)

      resolve &Resolvers.Directory.create_network/3
      middleware RadiatorWeb.ChangesetMiddleware
    end

    @desc "Update a network"
    field :update_network, type: :network do
      arg :id, non_null(:id)
      arg :network, non_null(:network_input)
      arg :image, :upload

      resolve &Resolvers.Directory.update_network/3
      middleware RadiatorWeb.ChangesetMiddleware
    end

    @desc "Create a podcast"
    field :create_podcast, type: :podcast do
      arg :podcast, non_null(:podcast_input)
      arg :network_id, non_null(:integer)

      resolve &Resolvers.Directory.create_podcast/3
      middleware RadiatorWeb.ChangesetMiddleware
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
      arg :podcast, non_null(:podcast_input)

      resolve &Resolvers.Directory.update_podcast/3
      middleware RadiatorWeb.ChangesetMiddleware
    end

    @desc "Delete a podcast"
    field :delete_podcast, type: :podcast do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.delete_podcast/3
    end

    # todo: do we still need this?
    field :create_upload, :rad_upload do
      arg :filename, non_null(:string)

      resolve &Resolvers.Storage.create_upload/3
    end

    @desc "Upload a single audio file to an episode"
    field :upload_episode_audio, type: :audio_file do
      arg :episode_id, non_null(:integer)
      arg :audio, :upload

      resolve &Resolvers.Storage.upload_episode_audio/3
    end

    @desc "Upload a single audio file to a network"
    field :upload_network_audio, type: :audio_file do
      arg :network_id, non_null(:integer)
      arg :audio, :upload

      resolve &Resolvers.Storage.upload_episode_audio/3
    end

    @desc "Create an episode"
    field :create_episode, type: :episode do
      arg :podcast_id, non_null(:id)
      arg :episode, non_null(:episode_input)

      resolve &Resolvers.Directory.create_episode/3
      middleware RadiatorWeb.ChangesetMiddleware
    end

    @desc "Update an episode"
    field :update_episode, type: :episode do
      arg :id, non_null(:id)
      arg :episode, non_null(:episode_input)

      resolve &Resolvers.Directory.update_episode/3
      middleware RadiatorWeb.ChangesetMiddleware
    end

    @desc "Delete an episode"
    field :delete_episode, type: :episode do
      arg :id, non_null(:id)

      resolve &Resolvers.Directory.delete_episode/3
    end

    @desc "Set chapters for an episode"
    field :set_chapters, type: :episode do
      arg :id, non_null(:id)
      arg :chapters, non_null(:string)
      arg :type, non_null(:string)

      resolve &Resolvers.Directory.set_episode_chapters/3
    end
  end
end
