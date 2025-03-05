defmodule Radiator.Outline.Event.NodeMovedToNewContainer do
  @moduledoc false
  defstruct [
    :event_id,
    :node,
    :user_id,
    :old_prev,
    :old_next,
    :next,
    :old_container_id,
    :container_id,
    :children
  ]
end
