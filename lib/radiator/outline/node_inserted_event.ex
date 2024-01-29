defmodule Radiator.Outline.NodeInsertedEvent do
  alias Radiator.Outline.Node

  # typespec .. wont need without dialyzer
  @type t :: %__MODULE__{
          parent_node: Node.t(),
          timestamp: DateTime.t(),
          content: String.t(),
          creator_id: Integer.t()
        }
  defstruct [:parent_node, :timestamp, :content, :creator_id]

  @enforce_keys [
    :patient_id,
    :to_id,
    :to_entity,
    :target
  ]
  @derive Jason.Encoder
end
