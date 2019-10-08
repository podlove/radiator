defmodule RadiatorWeb.Api.AuthenticationControllerTest do
  use RadiatorWeb.ConnCase

  describe "signup and verifcation" do
    test "signup with valid data creates user", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some_valid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      assert %{"user" => %{"name" => "some_valid_username"}} = json_response(conn, 201)
    end

    test "signup with invalid data creates error", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some invalid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      assert %{"errors" => _} = json_response(conn, 200)
    end
  end
end
