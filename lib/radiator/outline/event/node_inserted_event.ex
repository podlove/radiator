defmodule Radiator.Outline.Event.NodeInsertedEvent do
  @moduledoc false

  defstruct [:event_id, :node, :user_id, :next, :outline_node_container_id, :content]
end
