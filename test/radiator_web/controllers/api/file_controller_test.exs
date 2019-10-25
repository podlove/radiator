defmodule RadiatorWeb.Api.FileControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  describe "create file" do
    test "succeeds", %{conn: conn, user: user} do
      network = insert(:network) |> owned_by(user)

      upload = %Plug.Upload{
        path: "test/fixtures/pling.mp3",
        filename: "pling.mp3"
      }

      conn = post(conn, Routes.api_network_file_path(conn, :create, network.id), file: upload)

      assert %{"size" => 8476, "id" => file_id} = json_response(conn, 201)

      conn =
        conn
        |> recycle()
        |> get(Routes.api_file_path(conn, :show, file_id))

      assert %{"size" => 8476, "id" => ^file_id} = json_response(conn, 200)
    end
  end
end
