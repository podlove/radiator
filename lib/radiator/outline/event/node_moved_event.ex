defmodule Radiator.Outline.Event.NodeMovedEvent do
  @moduledoc false
  defstruct [
    :event_id,
    :node_id,
    :parent_id,
    :prev_id,
    :user_id,
    :old_prev_id,
    :old_next_id,
    :next_id
  ]
end
