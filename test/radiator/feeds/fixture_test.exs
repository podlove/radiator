defmodule Radiator.Feeds.FixtureTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures

  test "minimal.xml is well-formed and holds five items" do
    xml = FeedFixtures.read!("minimal.xml")

    assert {:ok, {"rss", _attrs, children}} = Saxy.SimpleForm.parse_string(xml)

    assert [{"channel", _, channel_children}] =
             Enum.filter(children, &match?({"channel", _, _}, &1))

    assert Enum.count(channel_children, &match?({"item", _, _}, &1)) == 5
  end

  test "xmlns:psc is bound on psc:chapters, not on the root element" do
    xml = FeedFixtures.read!("minimal.xml")

    refute String.contains?(xml, ~s(<rss xmlns:psc))
    assert String.contains?(xml, ~s(<psc:chapters xmlns:psc="http://podlove.org/simple-chapters"))
  end
end
