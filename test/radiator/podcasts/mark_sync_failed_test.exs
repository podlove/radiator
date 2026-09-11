defmodule Radiator.Podcasts.MarkSyncFailedTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.FeedSyncError

  setup do
    user = generate(user())

    %{podcast: Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)}
  end

  test "records the status, the message and the check timestamp", %{podcast: podcast} do
    failed =
      Ash.update!(podcast, %{error: {:http_status, 404}},
        action: :mark_sync_failed,
        authorize?: false
      )

    assert failed.sync_status == :failed
    assert failed.last_sync_error =~ "404"
    assert failed.last_checked_at != nil
  end

  test "stamps last_checked_at so a broken scheduled feed is not hammered", %{podcast: podcast} do
    failed =
      Ash.update!(podcast, %{error: :timeout}, action: :mark_sync_failed, authorize?: false)

    assert DateTime.diff(DateTime.utc_now(), failed.last_checked_at, :second) < 5
  end

  test "renders an Ash error without blowing up", %{podcast: podcast} do
    error = Ash.Error.to_ash_error(%RuntimeError{message: "boom"})
    failed = Ash.update!(podcast, %{error: error}, action: :mark_sync_failed, authorize?: false)

    assert is_binary(failed.last_sync_error)
    assert failed.last_sync_error != ""
  end

  test "renders a wrapped feed error as one readable line", %{podcast: podcast} do
    error = %Ash.Error.Invalid{errors: [FeedSyncError.from_reason({:http_status, 429, 120})]}
    failed = Ash.update!(podcast, %{error: error}, action: :mark_sync_failed, authorize?: false)

    assert failed.last_sync_error == "HTTP 429, retry after 120 s"
  end

  test "truncates a very long message", %{podcast: podcast} do
    failed =
      Ash.update!(podcast, %{error: String.duplicate("x", 5_000)},
        action: :mark_sync_failed,
        authorize?: false
      )

    assert String.length(failed.last_sync_error) <= 1_000
  end
end
