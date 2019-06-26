defmodule RadiatorWeb.Api.NetworkControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_authenticated_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  describe "create network" do
    test "renders network when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_network_path(conn, :create), network: %{title: "example"})

      assert %{"title" => "example"} = json_response(conn, 201)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_network_path(conn, :create), network: %{})

      assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    end

    test "renders errors no user is present", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> post(Routes.api_network_path(conn, :create), network: %{})

      assert "Unauthorized" = json_response(conn, 401)
    end
  end

  describe "show network" do
    test "renders a network", %{conn: conn, user: user} do
      network = insert(:network) |> owned_by(user)

      conn = get(conn, Routes.api_network_path(conn, :show, network.id))

      assert response = json_response(conn, 200)
      assert Map.get(response, "id") == network.id
      assert Map.get(response, "title") == network.title
    end

    test "renders an error if permissions missing", %{conn: conn} do
      network = insert(:network)

      conn = get(conn, Routes.api_network_path(conn, :show, network.id))

      assert response = json_response(conn, 401)
    end
  end
end
