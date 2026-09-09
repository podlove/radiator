defmodule Radiator.Podcasts.SyncStrategy do
  @moduledoc """
  How a podcast is reconciled with its feed.

  `:manual` means a one-off import; a manual sync stays possible at any time.
  `:scheduled` additionally means recurring reconciliation.
  """

  use Ash.Type.Enum,
    values: [
      manual: [label: "Nur einmaliger Import"],
      scheduled: [label: "Regelmäßiger Sync"]
    ]

  @doc ~S(Label/value pairs for `<.input type="select">`.)
  def options, do: Enum.map(values(), &{label(&1), &1})
end
