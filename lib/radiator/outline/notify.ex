defmodule Radiator.Outline.Notify do
  @moduledoc """
  Inform all connected users on changes.
  """

  alias Phoenix.PubSub

  @topic "outline-node"

  def broadcast_node_action({:ok, node}, action, socket_id) do
    PubSub.broadcast(Radiator.PubSub, @topic, {action, node, socket_id})

    {:ok, node}
  end

  def broadcast_node_action({:error, error}, _action, _socket_id), do: {:error, error}
end
