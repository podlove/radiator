defmodule Radiator.Outline.Dispatch do
  @moduledoc false

  alias Radiator.Outline.Event
  alias Radiator.Outline.EventProducer

  def insert_node(attributes, user_id, event_id) do
    "insert_node"
    |> Event.build(attributes, user_id, event_id)
    |> EventProducer.enqueue()
  end

  # TODO
  # update_node
  # delete_node
  # move_node

  # list_node different case, sync call
end
