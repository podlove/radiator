defmodule RadiatorWeb.GraphQL.Admin.Types do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias RadiatorWeb.GraphQL.Admin.Resolvers, as: AdminResolvers
  alias RadiatorWeb.GraphQL.Public.Resolvers, as: PublicResolvers

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

    field :display_name, :string do
      resolve fn user, _, _ -> {:ok, user.profile.display_name} end
    end

    field :email, :string

    field :image, :string do
      resolve &AdminResolvers.Editor.get_image_url/3
    end
  end

  @desc "A radiator instance user accessible to others"
  object :public_user do
    field :username, :string do
      resolve fn user, _, _ -> {:ok, user.name} end
    end

    field :display_name, :string do
      resolve fn user, _, _ -> {:ok, user.profile.display_name} end
    end

    field :image, :string do
      resolve &AdminResolvers.Editor.get_image_url/3
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
      resolve &AdminResolvers.Editor.get_image_url/3
    end
  end

  @desc "A network"
  object :network do
    field :id, non_null(:id)
    field :title, :string
    field :slug, :string

    field :image, :string do
      resolve &AdminResolvers.Editor.get_image_url/3
    end

    field :podcasts, list_of(:podcast) do
      resolve &AdminResolvers.Editor.list_podcasts/3
    end

    field :audio_publications, list_of(:audio_publication) do
      resolve &AdminResolvers.Editor.list_audio_publications/3
    end

    field :people, list_of(:person) do
      resolve &AdminResolvers.Editor.list_people/3
    end

    field :collaborators, list_of(:collaborator) do
      resolve &AdminResolvers.Editor.list_collaborators/3
    end

    field :statistics, :statistics do
      resolve &AdminResolvers.Statistics.get_statistics/3
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
      resolve &AdminResolvers.Editor.get_image_url/3
    end

    field :language, :string
    field :last_built_at, :datetime
    field :owner_email, :string
    field :owner_name, :string

    @desc "drafted, scheduled, published, depublished"
    field :publish_state, :string
    field :published_at, :datetime

    field :slug, :string

    field :public_page, :string do
      resolve &PublicResolvers.Directory.get_public_page/3
    end

    field :published_feeds, list_of(:published_podcast_feed_info) do
      resolve &PublicResolvers.Directory.get_public_feeds/3
    end

    field :episodes, list_of(:episode) do
      arg :published, type: :published, default_value: :any
      arg :page, type: :integer, default_value: 1
      arg :items_per_page, type: :integer, default_value: 10
      arg :order_by, type: :episode_order, default_value: :published_at
      arg :order, type: :sort_order, default_value: :desc

      resolve &AdminResolvers.Editor.get_episodes/3
    end

    field :episodes_count, :integer do
      resolve &AdminResolvers.Editor.get_episodes_count/3
    end

    field :contributions, list_of(:contribution) do
      resolve &AdminResolvers.Editor.get_contributions/3
    end

    field :statistics, :statistics do
      resolve &AdminResolvers.Statistics.get_statistics/3
    end
  end

  object :statistics do
    field :downloads, :statistic_metric
    field :listeners, :statistic_metric
    field :user_agents, :statistic_agent_metric
  end

  object :statistic_agent_metric do
    field :total, :user_agent_metrics do
      resolve &AdminResolvers.Statistics.get_total_statistics/3
    end

    field :monthly, list_of(:statistic_agent_time_values) do
      arg :from, type: :simple_month, default_value: nil
      arg :until, type: :simple_month, default_value: nil

      resolve &AdminResolvers.Statistics.get_monthly_statistics/3
    end
  end

  object :statistic_metric do
    field :total, :integer do
      resolve &AdminResolvers.Statistics.get_total_statistics/3
    end

    field :monthly, list_of(:statistic_time_values) do
      arg :from, type: :simple_month, default_value: nil
      arg :until, type: :simple_month, default_value: nil

      resolve &AdminResolvers.Statistics.get_monthly_statistics/3
    end

    field :daily, list_of(:statistic_time_values) do
      arg :from, type: :simple_day, default_value: nil
      arg :until, type: :simple_day, default_value: nil

      resolve &AdminResolvers.Statistics.get_daily_statistics/3
    end
  end

  object :statistic_time_values do
    field :date, :string
    field :value, :integer
  end

  object :statistic_agent_time_values do
    field :date, :string
    field :value, :user_agent_metrics
  end

  object :user_agent_metrics do
    field :client_name, list_of(:user_agent_ranked_item)
    field :client_type, list_of(:user_agent_ranked_item)
    field :device_type, list_of(:user_agent_ranked_item)
    field :os_name, list_of(:user_agent_ranked_item)
  end

  object :user_agent_ranked_item do
    field :absolute, :integer
    field :percent, :float
    field :title, :string
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
      resolve &AdminResolvers.Editor.get_image_url/3
    end

    field :number, :integer

    @desc "drafted, scheduled, published, depublished"
    field :publish_state, :string
    field :published_at, :datetime

    field :slug, :string

    field :public_page, :string do
      resolve &PublicResolvers.Directory.get_public_page/3
    end

    field :podcast, :podcast do
      resolve &AdminResolvers.Editor.find_podcast/3
    end

    field :audio, :audio do
      resolve dataloader(Directory.Editor)
    end
  end

  @desc "An audio object"
  object :audio do
    field :id, non_null(:id)
    field :duration, :integer

    field :duration_string, :string do
      resolve &AdminResolvers.Editor.get_duration_string/3
    end

    field :image, :string do
      resolve &AdminResolvers.Editor.get_image_url/3
    end

    field :chapters, list_of(:chapter) do
      arg :order, type: :sort_order, default_value: :asc

      resolve dataloader(Radiator.AudioMeta, :chapters)
    end

    field :episodes, list_of(:episode) do
      resolve &AdminResolvers.Editor.get_episodes/3
    end

    field :audio_publication, :audio_publication do
      resolve &AdminResolvers.Editor.get_audio_publication/3
    end

    field :audio_files, list_of(:audio_file) do
      resolve dataloader(Directory.Editor)
    end

    field :contributions, list_of(:contribution) do
      resolve dataloader(Directory.Editor)
    end
  end

  object :audio_publication do
    @desc "drafted, scheduled, published, depublished"
    field :id, :integer
    field :title, :string
    field :publish_state, :string
    field :published_at, :datetime

    field :audio, :audio do
      resolve &AdminResolvers.Editor.find_audio/3
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
