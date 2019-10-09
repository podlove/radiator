defmodule RadiatorWeb.Api.AuthenticationControllerTest do
  use RadiatorWeb.ConnCase

  describe "Singup and Verification:" do
    test "signup with valid data creates user", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some_valid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      assert %{"user" => %{"name" => "some_valid_username"}} = json_response(conn, 201)
    end

    test "signup - invalid data -> ⚠️", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some invalid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      assert %{"errors" => _} = json_response(conn, 200)
    end

    test "resend_verification_email - endpoint responds", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some_valid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      conn =
        conn
        |> recycle()
        |> post(Routes.api_authentication_path(conn, :resend_verification_email),
          name_or_email: "some_valid_username"
        )

      assert %{"verification" => "sent"} = json_response(conn, 200)
    end

    test "reset_password - endpoint responds", %{conn: conn} do
      conn =
        post(conn, Routes.api_authentication_path(conn, :signup),
          name: "some_valid_username",
          password: "password",
          email: "mail@nowhere.it"
        )

      conn =
        conn
        |> recycle()
        |> post(Routes.api_authentication_path(conn, :reset_password),
          name_or_email: "some_valid_username"
        )

      assert %{"reset" => "sent"} = json_response(conn, 200)
    end
  end
end
