defmodule RadiatorWeb.GraphQL.FeedInfo.Types do
  use Absinthe.Schema.Notation

  @desc "Info about podcast feeds found at an url"
  object :feed_info do
    field :title, :string
    field :subtitle, :string
    field :link, :string
    field :image, :string
    field :suggested_short_id, :string
    field :feeds, list_of(:podcast_feed)
  end

  @desc "A Podcast feed"
  object :podcast_feed do
    field :feed_url, :string
    field :link, :string

    field :title, :string
    field :subtitle, :string
    field :summary, :string
    field :description, :string
    field :author, :string
    field :image, :string
    field :enclosure_type, :string

    field :episodes, list_of(:podcast_feed_episode)

    field :episode_count, non_null(:integer)
    field :waiting_for_pages, non_null(:boolean)
  end

  @desc "A podcast feed episode"
  object :podcast_feed_episode do
    field :guid, :string
    field :title, :string
    field :subtitle, :string
    field :summary, :string
    field :description, :string
    field :content_encoded, :string
    field :duration, :string

    field :link, :string
    field :season, :string
    field :episode, :string

    field :image, :string
    field :enclosure_url, :string
    field :enclosure_type, :string
  end
end
