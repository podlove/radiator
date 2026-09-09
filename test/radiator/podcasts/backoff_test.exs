defmodule Radiator.Podcasts.BackoffTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.FeedSyncError
  alias Radiator.Podcasts.Podcast.Backoff

  # What Oban hands back is never the feed client's tuple: the action wraps it
  # in an `Ash.Error.Invalid` whose `errors` hold the `FeedSyncError`.
  defp job(attempt, reason) do
    wrapped = %Ash.Error.Invalid{errors: [FeedSyncError.from_reason(reason)]}

    %Oban.Job{attempt: attempt, unsaved_error: %{kind: :error, reason: wrapped, stacktrace: []}}
  end

  test "honours Retry-After on 429" do
    assert Backoff.for_job(job(1, {:http_status, 429, 120})) == 120
  end

  test "honours Retry-After on 503" do
    assert Backoff.for_job(job(2, {:http_status, 503, 45})) == 45
  end

  test "caps an absurd Retry-After" do
    assert Backoff.for_job(job(1, {:http_status, 429, 99_999})) == 3_600
  end

  test "grows exponentially for everything else" do
    assert Backoff.for_job(job(1, :timeout)) == 16
    assert Backoff.for_job(job(1, :timeout)) < Backoff.for_job(job(3, :timeout))
  end

  test "survives a job without an error" do
    assert Backoff.for_job(%Oban.Job{attempt: 1, unsaved_error: nil}) > 0
  end
end
