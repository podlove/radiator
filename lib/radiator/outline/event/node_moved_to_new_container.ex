defmodule Radiator.Outline.Event.NodeMovedToNewContainer do
  @moduledoc false
  defstruct [
    :event_id,
    :node,
    :user_id,
    :old_prev,
    :old_next,
    :next,
    :old_outline_node_container_id,
    :new_outline_node_container_id,
    :children
  ]
end
