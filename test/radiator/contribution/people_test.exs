defmodule Radiator.ContributionTest do
  use Radiator.DataCase

  alias Radiator.Directory.Editor

  import Radiator.Factory

  describe "people" do
    alias Radiator.Contribution.Person

    test "create_person/1 with valid data creates a person" do
      network = insert(:network)

      assert {:ok, %Person{} = person} =
               Editor.Editor.create_person(network, %{
                 display_name: "Tim Pritlove (@timpritlove)",
                 name: "Tim Pritlove",
                 nick: "timpritlove",
                 email: "tim@metaebene.me",
                 link: "https://metaebene.me"
               })

      assert person.nick == "timpritlove"
    end

    test "create_person/1 with invalid data does not create a person" do
      network = insert(:network)

      assert {:error, _} =
               Editor.Editor.create_person(network, %{
                 name: "Tim Pritlove",
                 nick: "timpritlove",
                 email: "tim@metaebene.me",
                 link: "https://metaebene.me"
               })
    end
  end
end
