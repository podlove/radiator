defmodule RadiatorWeb.GraphQL.Common.Types do
  use Absinthe.Schema.Notation

  @desc "A chapter in an episode"
  object :chapter do
    field :start, :integer

    field :start_string, :string do
      resolve &RadiatorWeb.GraphQL.Admin.Resolvers.Editor.get_duration_string/3
    end

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

  @desc "A user API session"
  object :session do
    field :username, :string
    field :token, :string
    field :expires_at, :datetime
  end

  require Logger

  @desc "A record of a Person having contributed"
  object :contribution do
    field :id, non_null(:id)
    field :position, :float

    field :person, :person do
      resolve fn sub, _, _ -> {:ok, sub.person} end
    end

    field :contribution_role, :contribution_role do
      resolve fn sub, _, _ -> {:ok, sub.role} end
    end
  end

  @desc "A Contribution Role"
  object :contribution_role do
    field :id, non_null(:id)
    field :title, :string

    field :is_public, :boolean do
      resolve fn %Radiator.Contribution.Role{public?: result}, _, _ -> {:ok, result} end
    end
  end
end
