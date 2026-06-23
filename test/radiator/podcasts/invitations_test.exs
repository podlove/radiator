defmodule Radiator.Podcasts.InvitationsTest do
  use Radiator.DataCase, async: true

  import Radiator.Generator
  import Swoosh.TestAssertions

  alias Radiator.Podcasts

  test "invite_new_participants invites passwordless participants via a magic-link deep link" do
    podcast = generate(podcast())
    email = "guest-#{System.unique_integer([:positive])}@example.com"

    episode =
      Radiator.Podcasts.Episode
      |> Ash.Changeset.for_create(
        :create,
        %{title: "Test episode", podcast_id: podcast.id, participants: [%{email: email}]},
        authorize?: false
      )
      |> Ash.create!()

    {:ok, invited} = Podcasts.invite_new_participants(episode)

    assert [invited_user] = invited
    assert to_string(invited_user.email) == email

    # Creating the passwordless user also triggers the confirmation add-on; the
    # voting invitation is the email we care about here.
    assert_email_sent(subject: "Confirm your email address")

    expected_return_to =
      URI.encode_www_form("/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

    assert_email_sent(fn mail ->
      assert mail.subject == "Hier kannst du abstimmen"
      assert mail.to == [{"", email}]
      assert mail.html_body =~ "/auth/user/magic_link?token="
      assert mail.html_body =~ "return_to=#{expected_return_to}"
    end)
  end

  test "invite_new_participants ignores already onboarded participants" do
    podcast = generate(podcast())

    # A user with a password is considered onboarded and must not be invited.
    onboarded =
      Radiator.Accounts.User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{email: "member@example.com", password: "password1234", password_confirmation: "password1234"},
        authorize?: false
      )
      |> Ash.create!()

    episode =
      Radiator.Podcasts.Episode
      |> Ash.Changeset.for_create(
        :create,
        %{
          title: "Test episode",
          podcast_id: podcast.id,
          participants: [%{email: to_string(onboarded.email)}]
        },
        authorize?: false
      )
      |> Ash.create!()

    assert {:ok, []} = Podcasts.invite_new_participants(episode)
  end
end
