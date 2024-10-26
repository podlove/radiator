defmodule Radiator.Resources.UrlWorkerTest do
  use Radiator.DataCase

  alias Radiator.Outline.Node
  alias Radiator.OutlineFixtures
  alias Radiator.Resources.UrlWorker

  describe "extract_url_positions/1" do
    test "extracts urls in text" do
      content = """
        bad: https://www.theatlantic.com/politics/archive/2024/10/donald-trump-elon-musk-butler/680174/
        racism: https://www.newyorker.com/magazine/2024/10/14/trumps-dangerous-immigration-obsession
        what else?
      """

      node_id = OutlineFixtures.node_fixture(content: content).uuid
      UrlWorker.perform(node_id)

      updated_node =
        Node
        |> Repo.get(node_id)
        |> Repo.preload(:urls)

      first_url = Enum.find(updated_node.urls, fn url -> url.start_bytes == 7 end)
      second_url = Enum.find(updated_node.urls, fn url -> url.start_bytes == 108 end)
      assert 2 == Enum.count(updated_node.urls)

      assert first_url.url ==
               "https://www.theatlantic.com/politics/archive/2024/10/donald-trump-elon-musk-butler/680174/"

      assert second_url.url ==
               "https://www.newyorker.com/magazine/2024/10/14/trumps-dangerous-immigration-obsession"
    end
  end
end
