defmodule Radiator.Podcasts.SyncStatus do
  @moduledoc """
  The outcome of the most recent feed reconciliation.

  `:idle` is the starting value and means "never checked". `:pending` means
  "a sync was requested" and is set exclusively by the `:import` and
  `:request_sync` actions — the trigger selects on it. There is deliberately
  no `:running` state; Oban handles concurrency.
  """

  use Ash.Type.Enum,
    values: [
      idle: [label: "Noch nicht geprüft"],
      pending: [label: "Sync angefordert"],
      succeeded: [label: "Erfolgreich"],
      failed: [label: "Fehlgeschlagen"]
    ]

  @doc ~S(Label/value pairs for `<.input type="select">`.)
  def options, do: Enum.map(values(), &{label(&1), &1})
end
