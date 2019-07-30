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

  test "has_permission/3 for audio publication" do
    user = insert(:user)
    user_other = insert(:user)

    network = insert(:network) |> owned_by(user)
    audio = insert(:audio)

    audio_publication = insert(:audio_publication, network: network, audio: audio)

    assert Permission.has_permission(user, audio_publication, :own)
    refute Permission.has_permission(user_other, audio_publication, :own)
  end

  test "has_permission/3 for episode" do
    user = insert(:user)
    user_other = insert(:user)

    episode = insert(:episode) |> owned_by(user)

    assert Permission.has_permission(user, episode, :own)
    refute Permission.has_permission(user_other, episode, :own)
  end
end
