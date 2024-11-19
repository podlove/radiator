defmodule Radiator.Accounts.RaindropClientTest do
  use Radiator.DataCase

  import Radiator.AccountsFixtures

  alias Radiator.Accounts.RaindropClient

  describe "access_enabled?" do
    test "true when a webservice entry for this user exists" do
      webservice = raindrop_service_fixture()
      assert RaindropClient.access_enabled?(webservice.user_id)
    end

    test "false when no webservice entry exists" do
      user = user_fixture()
      refute RaindropClient.access_enabled?(user.id)
    end

    test "false when no webservice entry for this user exists" do
      other_user_id = raindrop_service_fixture().user_id
      user = user_fixture()
      assert other_user_id != user.id
      refute RaindropClient.access_enabled?(user.id)
    end
  end
end
