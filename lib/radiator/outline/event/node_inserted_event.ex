defmodule Radiator.Outline.Event.NodeInsertedEvent do
  @moduledoc false

  defstruct [:event_id, :node, :user_id, :next, :container_id, :content]
end
