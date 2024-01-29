defmodule Radiator.Outline.InsertNodeCommand do
  @enforce_keys [:parent_id, :owner_id, :episode_id]

  defstruct [
    # content of the new node
    :content,
    # id of parent node
    :parent_id,
    # id of user who created the node
    :owner_id,
    # id of episode the new node should be associated with
    :episode_id
  ]

  # TODO format ?
  # TODO validation episode id must match episode id of parent node, so do we need it? @doc """
  #   other wise we need a solution for the first node in an episode, perhaps we create root node with an episode

  alias Radiator.Accounts.User
  alias Radiator.Outline.Node
  alias Radiator.Podcast.Episode

  def execute(parent_id, nil, _episode_id),
    do: {:error, :invalid__owner_id}

  def(execute(%Node{parent_id: parent_id}, %User{id: owner_id}, %Episode{id: episode_id})) do
    # TODO: Implement the logic for the command here
  end
end

InsertNodeCommand
