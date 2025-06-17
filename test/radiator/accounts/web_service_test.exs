defmodule Radiator.Accounts.WebServiceTest do
  use Radiator.DataCase, async: false

  import Radiator.AccountsFixtures
  alias Radiator.Accounts.WebService
  alias Radiator.Repo

  describe "update_last_sync_statement/2" do
    setup do
      %{web_service: raindrop_service_fixture()}
    end

    test "updates last_sync with provided time", %{web_service: web_service} do
      sync_time = DateTime.utc_now() |> DateTime.shift(hour: -1) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync_statement(web_service, sync_time)

      assert changeset.valid?
      assert get_change(changeset, :last_sync) == sync_time
    end

    test "fails validation when provided time is in the future", %{web_service: web_service} do
      future_time = DateTime.utc_now() |> DateTime.shift(hour: 1) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync_statement(web_service, future_time)

      refute changeset.valid?
      assert "cannot be in the future" in errors_on(changeset).last_sync
    end

    test "can be used to persist last_sync to database", %{web_service: web_service} do
      sync_time = DateTime.utc_now() |> DateTime.shift(minute: -30) |> DateTime.truncate(:second)

      changeset = WebService.update_last_sync_statement(web_service, sync_time)
      {:ok, updated_service} = Repo.update(changeset)

      assert updated_service.last_sync == sync_time
    end
  end
end
