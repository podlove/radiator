defmodule RadiatorWeb.GraphQL.Resolvers.Editor do
  alias Radiator.Directory.Editor

  def create_network(_parent, %{network: args}, %{context: %{authenticated_user: user}}) do
    case Editor.Owner.create_network(user, args) do
      {:ok, %{network: network}} -> {:ok, network}
      _ -> {:error, "Could not create network with #{args}"}
    end
  end
end
