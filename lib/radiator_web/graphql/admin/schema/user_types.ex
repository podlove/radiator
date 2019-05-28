defmodule RadiatorWeb.GraphQL.Admin.Schema.UserTypes do
  use Absinthe.Schema.Notation

  @desc "A user API session"
  object :session do
    field :username, :string
    field :token, :string
  end
end
