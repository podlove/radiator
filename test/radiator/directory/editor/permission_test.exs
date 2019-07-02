defmodule Radiator.Directory.Editor.PermissionTest do
  use Radiator.DataCase

  import Radiator.Factory

  alias Radiator.Directory.Editor.Permission

  test "has_permission/3 for podcasts" do
    user = insert(:user)
    user_other = insert(:user)

    podcast = insert(:podcast) |> owned_by(user)

    assert Permission.has_permission(user, podcast, :own)
    refute Permission.has_permission(user_other, podcast, :own)
  end

  test "has_permission/3 for podcasts via parent network" do
    user = insert(:user)
    user_other = insert(:user)

    network = insert(:network) |> owned_by(user)
    podcast = insert(:podcast, network: network)

    assert Permission.has_permission(user, podcast, :own)
    refute Permission.has_permission(user_other, podcast, :own)
  end

  test "has_permission/3 for audio via parent network" do
    user = insert(:user)
    user_other = insert(:user)

    network = insert(:network) |> owned_by(user)
    audio = insert(:audio, network: network)

    assert Permission.has_permission(user, audio, :own)
    refute Permission.has_permission(user_other, audio, :own)
  end

  test "has_permission/3 for audio via parent episode" do
    user = insert(:user)
    user_other = insert(:user)

    episode = insert(:episode) |> owned_by(user)
    audio = insert(:audio, episodes: [episode])

    assert Permission.has_permission(user, audio, :own)
    refute Permission.has_permission(user_other, audio, :own)
  end
end
