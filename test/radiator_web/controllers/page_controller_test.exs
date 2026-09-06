defmodule RadiatorWeb.PageControllerTest do
  use RadiatorWeb.FeatureCase, async: true

  test "can render imprint page", %{conn: conn} do
    conn
    |> visit(~p"/impressum")
    |> assert_has(~s|meta[name=robots][content="noindex,nofollow"]|)
    |> assert_has("title", text: "Radiator")
    |> assert_has("h1", text: "Imprint")
  end
end
