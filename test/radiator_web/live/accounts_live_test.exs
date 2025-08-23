defmodule RadiatorWeb.AccountsLiveTest do
  use RadiatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import Radiator.AccountsFixtures

  describe "Accounts page is restricted" do
    test "can render if user is logged in", %{conn: conn} do
      user = user_fixture()
      {:ok, _live, html} = conn |> log_in_user(user) |> live(~p"/admin/accounts")

      assert html =~ "Accounts</h1>"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/accounts")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Accounts page" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "lists all users", %{conn: conn, user: user} do
      {:ok, _live, html} = live(conn, ~p"/admin/accounts")

      assert html =~ "Accounts</h1>"
      assert html =~ user.email
    end
  end
end
