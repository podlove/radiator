defmodule RadiatorWeb.GraphQL.Admin.Types do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias RadiatorWeb.GraphQL.Admin.Resolvers

  alias Radiator.Directory
  alias Radiator.Directory.{Network, Podcast}

  @desc "A type of access permission."
  enum :permission do
    value :readonly, description: "viewer"
    value :edit, description: "editor"
    value :manage, description: "manager"
    value :own, description: "owner"
  end

  @desc "A radiator instance user that is allowed to work on this subject"
  object :collaborator do
    field :user, :user
    field :subject, :permission_subject
    field :permission, :permission
  end

  union :permission_subject do
    description "A subject for permissions / user roles. E.g. a Network, Podcast, etc."

    types [:network, :podcast]

    resolve_type fn
      %Network{}, _ -> :network
      %Podcast{}, _ -> :podcast
    end
  end

  @desc "A radiator instance user accessible to admins and yourself"
  object :user do
    field :username, :string do
      resolve fn user, _, _ -> {:ok, user.name} end
    end

    field :display_name, :string
    field :email, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end
  end

  @desc "A radiator instance user accessible to others"
  object :public_user do
    field :username, :string do
      resolve fn user, _, _ -> {:ok, user.name} end
    end

    field :display_name, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end
  end

  @desc "A radiator instance person"
  object :person do
    field :id, non_null(:id)
    field :display_name, :string
    field :name, :string
    field :nick, :string
    field :email, :string
    field :link, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end
  end

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

    field :audio_publications, list_of(:audio_publication) do
      resolve &Resolvers.Editor.list_audio_publications/3
    end

    field :people, list_of(:person) do
      resolve &Resolvers.Editor.list_people/3
    end

    field :collaborators, list_of(:collaborator) do
      resolve &Resolvers.Editor.list_collaborators/3
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
    field :short_id, :string
    field :title, :string
    field :subtitle, :string
    field :summary, :string

    field :author, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :language, :string
    field :last_built_at, :datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :datetime
    field :slug, :string

    field :is_published, :boolean do
      resolve &Resolvers.Editor.is_published/3
    end

    field :episodes, list_of(:episode) do
      arg :published, type: :published, default_value: :any
      arg :page, type: :integer, default_value: 1
      arg :items_per_page, type: :integer, default_value: 10
      arg :order_by, type: :episode_order, default_value: :published_at
      arg :order, type: :sort_order, default_value: :desc

      resolve &Resolvers.Editor.get_episodes/3
    end

    field :episodes_count, :integer do
      resolve &Resolvers.Editor.get_episodes_count/3
    end

    field :contributions, list_of(:contribution) do
      resolve &Resolvers.Editor.get_contributions/3
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

    field :guid, :string
    field :short_id, :string
    field :title, :string
    field :subtitle, :string

    field :summary, :string
    field :summary_html, :string
    field :summary_source, :string

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :number, :integer

    @desc "drafted, scheduled, published, depublished"
    field :publish_state, :string
    field :published_at, :datetime

    field :slug, :string

    field :is_published, :boolean do
      resolve &Resolvers.Editor.is_published/3
    end

    field :podcast, :podcast do
      resolve &Resolvers.Editor.find_podcast/3
    end

    field :audio, :audio do
      resolve dataloader(Directory)
    end
  end

  @desc "An audio object"
  object :audio do
    field :id, non_null(:id)
    field :duration, :integer

    field :duration_string, :string do
      resolve &Resolvers.Editor.get_duration_string/3
    end

    field :image, :string do
      resolve &Resolvers.Editor.get_image_url/3
    end

    field :chapters, list_of(:chapter) do
      arg :order, type: :sort_order, default_value: :asc

      resolve dataloader(Directory, :chapters)
    end

    field :episodes, list_of(:episode) do
      resolve &Resolvers.Editor.get_episodes/3
    end

    field :audio_publication, :audio_publication do
      resolve &Resolvers.Editor.get_audio_publication/3
    end

    field :audio_files, list_of(:audio_file) do
      resolve dataloader(Directory)
    end

    field :contributions, list_of(:contribution) do
      resolve dataloader(Directory)
    end
  end

  object :audio_publication do
    @desc "drafted, scheduled, published, depublished"
    field :id, :integer
    field :title, :string
    field :publish_state, :string
    field :published_at, :datetime

    field :audio, :audio do
      resolve &Resolvers.Editor.find_audio/3
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
