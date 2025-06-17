defmodule Features.RegisterTest do
  use PhoenixTest.Playwright.Case, async: false
  use RadiatorWeb, :verified_routes

  test "register", %{conn: conn} do
    conn
    |> visit(~p"/")
    |> click_link("Register")
    |> assert_has("body .phx-connected")
    |> fill_in("Email", with: "user@example.com")
    |> fill_in("Password", with: "Mb2.r5oHf-0t")
    |> click_button("Create an account")
    |> assert_has("#flash-info", text: "Success!")
    |> visit(~p"/users/settings")
    |> assert_has("h1", text: "Settings")
  end
end
