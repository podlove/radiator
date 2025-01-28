defmodule Radiator.Outline.Event.NodesMovedToContainerEvent do
  @moduledoc false

  defstruct [
    :event_id,
    :user_id,
    :nodes,
    :old_container_id,
    :new_container_id
  ]
end
