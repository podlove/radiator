defmodule RadiatorWeb.GraphQL.Common.Types do
  use Absinthe.Schema.Notation

  @desc "A chapter in an episode"
  object :chapter do
    field :start, :integer
    field :title, :string
    field :link, :string

    field :image, :string do
      resolve &RadiatorWeb.GraphQL.Public.Resolvers.Directory.get_image_url/3
    end
  end

  @desc "Audio File"
  object :audio_file do
    field :mime_type, :string
    field :byte_length, :integer
    field :title, :string
  end

  @desc "An audio enclosure"
  object :enclosure do
    field :url, :string
    field :type, :string
    field :length, :integer
  end

  @desc "A user API session"
  object :session do
    field :username, :string
    field :token, :string
  end
end
