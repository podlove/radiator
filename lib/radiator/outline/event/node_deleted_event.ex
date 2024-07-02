defmodule Radiator.Outline.Event.NodeDeletedEvent do
  @moduledoc false
  defstruct [:uuid, :node_id, :user_id, :children, :next_id]
end
