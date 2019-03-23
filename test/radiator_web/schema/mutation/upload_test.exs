defmodule RadiatorWeb.EpisodeControllerTest.Schema.Mutation.UploadTest do
  use RadiatorWeb.ConnCase, async: true

  @query """
  mutation ($filename: String!) {
    createUpload(filename: $filename) {
      uploadUrl
    }
  }
  """

  test "createUploads returns a URL", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: %{"filename" => "foobar"}

    assert %{"data" => %{"createUpload" => %{"uploadUrl" => url}}} = json_response(conn, 200)

    refute is_nil(url)
  end
end
