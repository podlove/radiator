defmodule Radiator.Accounts.WebServiceTest do
  use Radiator.DataCase, async: false

  import Radiator.AccountsFixtures
  alias Radiator.Accounts.Raindrop
  alias Radiator.Accounts.WebService
  alias Radiator.PodcastFixtures

  describe "get_raindrop_tokens/1" do
    setup do
      %{web_service: raindrop_service_fixture()}
    end

    test "returns the raindrop tokens", %{web_service: web_service} do
      fetched_web_service = Raindrop.get_raindrop_tokens(web_service.user_id)
      assert fetched_web_service.data == web_service.data
    end
  end

  describe "update_raindrop_tokens/4" do
    setup do
      user = user_fixture()

      web_service = %{
        user_id: user.id,
        access_token: "ae261404-11r4-47c0-bce3-e18a423da828",
        refresh_token: "c8080368-fad2-4a3f-b2c9-71d3z85011vb",
        expires_at:
          DateTime.utc_now() |> DateTime.shift(second: 1_209_599) |> DateTime.truncate(:second)
      }

      %{user: user, web_service: web_service}
    end

    test "creates a new entry if none exists", %{user: user, web_service: web_service} do
      count_before = Repo.aggregate(WebService, :count)

      Raindrop.update_raindrop_tokens(
        user.id,
        web_service.access_token,
        web_service.refresh_token,
        web_service.expires_at
      )

      count_after = Repo.aggregate(WebService, :count)
      assert count_after == count_before + 1

      %WebService{} = service = Raindrop.get_raindrop_tokens(user.id)

      assert service.data.access_token == web_service.access_token
      assert service.data.refresh_token == web_service.refresh_token
      assert service.data.expires_at == web_service.expires_at
    end

    test "updates the raindrop tokens", %{user: user, web_service: web_service} do
      # Create a new entry
      Raindrop.update_raindrop_tokens(
        user.id,
        web_service.access_token,
        web_service.refresh_token,
        web_service.expires_at
      )

      count_before = Repo.aggregate(WebService, :count)
      # Update the entry, must not create a new one
      Raindrop.update_raindrop_tokens(
        user.id,
        "new-access-token",
        "new-refresh-token",
        web_service.expires_at
      )

      count_after = Repo.aggregate(WebService, :count)
      assert count_after == count_before

      %WebService{} = service = Raindrop.get_raindrop_tokens(user.id)
      assert service.data.access_token == "new-access-token"
      assert service.data.refresh_token == "new-refresh-token"
    end
  end

  describe "connect_show_with_rainbow/3" do
    setup do
      %{web_service: raindrop_service_fixture(), show: PodcastFixtures.show_fixture()}
    end

    test "saves a show - collection connection in collection_mappings", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      service = Raindrop.get_raindrop_tokens(web_service.user_id)
      assert service.data.collection_mappings == %{"#{show.id}" => 42}
    end

    test "can add multiple shows", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      second_show = PodcastFixtures.show_fixture()
      third_show = PodcastFixtures.show_fixture()

      Raindrop.connect_show_with_raindrop(web_service.user_id, second_show.id, 23)
      Raindrop.connect_show_with_raindrop(web_service.user_id, third_show.id, 666)

      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      assert service.data.collection_mappings == %{
               "#{show.id}" => 42,
               "#{second_show.id}" => 23,
               "#{third_show.id}" => 666
             }
    end

    test "can override show", %{
      web_service: web_service,
      show: show
    } do
      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 42)

      Raindrop.connect_show_with_raindrop(web_service.user_id, show.id, 23)
      service = Raindrop.get_raindrop_tokens(web_service.user_id)

      assert service.data.collection_mappings == %{"#{show.id}" => 23}
    end
  end

  # describe "create/1" do
  #   test "creates a web service" do
  #     user = user_fixture()
  #     attrs = %{access_token: "token", refresh_token: "refresh", expires_at: DateTime.utc_now()}
  #     {:ok, web_service} = Accounts.create_web_service(user.id, "Raindrop", attrs)

  #     assert web_service.service_name == "Raindrop"
  #     assert web_service.user_id == user.id
  #   end

  #   test "returns an error when invalid" do
  #     user = user_fixture()
  #     attrs = %{access_token: "token", refresh_token: "refresh", expires_at: DateTime.utc_now()}
  #     {:error, %Ecto.Changeset{errors: errors}} = Accounts.create_web_service(user.id, nil, attrs)
  #     assert errors[:service_name] == {"can't be blank", [validation: :required]}
  #   end

  #   test "embeds access token, refresh token, and expires at" do
  #     user = user_fixture()
  #     attrs = %{access_token: "token", refresh_token: "refresh", expires_at: DateTime.utc_now()}
  #     {:ok, web_service} = Accounts.create_web_service(user.id, "Raindrop", attrs)

  #     assert web_service.data.access_token == "token"
  #     assert web_service.data.refresh_token == "refresh"
  #   end
  # end
end
