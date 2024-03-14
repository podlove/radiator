defmodule Radiator.Outline.Server do
  alias Radiator.Outline.Event

  def insert_node(attributes, user_id, event_id) do
    "insert_node"
    |> Event.build(attributes, user_id, event_id)
    |> Event.enqueue()

    # generate event
    #   send to Eventserver
    #      validate
    #         true->
    #           database action: insert node()
    #           create && persist event (event contains all attributes, user, event_id, timestamps)
    #           broadcast event (topic: episode_id)
    #           broadcast node (topic: episode_id)
    #         false->
    #           log error and return error (audit log)
    :ok
  end

  # TODO
  # update_node
  # delete_node
  # move_node

  # list_node different case, sync call
end
