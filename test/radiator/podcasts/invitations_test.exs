defmodule Radiator.Podcasts.InvitationsTest do
  use Radiator.DataCase, async: true

  import Radiator.Generator
  import Swoosh.TestAssertions

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode.Scheduling

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
        %{
          email: "member@example.com",
          password: "password1234",
          password_confirmation: "password1234"
        },
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

  test "notify_participants_of_result emails every participant, even without a vote or onboarding" do
    podcast = generate(podcast())

    onboarded_email = "member-#{System.unique_integer([:positive])}@example.com"
    newcomer_email = "guest-#{System.unique_integer([:positive])}@example.com"

    # onboarded participant: has a password (would be filtered out by invite_new_participants)
    _onboarded =
      Radiator.Accounts.User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{
          email: onboarded_email,
          password: "password1234",
          password_confirmation: "password1234"
        },
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
          participants: [%{email: onboarded_email}, %{email: newcomer_email}]
        },
        authorize?: false
      )
      |> Ash.create!()

    episode = Ash.load!(episode, [:participants], authorize?: false)
    owner = hd(episode.participants)

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(
        :create,
        %{
          episode_id: episode.id,
          owner_user_id: owner.id,
          proposed_datetimes: [~U[2026-04-18 22:00:00Z]]
        },
        authorize?: false
      )
      |> Ash.create()

    [proposal] = scheduling.proposals

    {:ok, _closed} =
      scheduling
      |> Ash.Changeset.for_update(
        :finalize,
        %{chosen_proposal_id: proposal.id, user_id: owner.id},
        authorize?: false
      )
      |> Ash.update()

    {:ok, participants} = Podcasts.notify_participants_of_result(episode)

    assert length(participants) == 2

    recipients =
      flush_result_emails()
      |> Enum.flat_map(& &1.to)
      |> Enum.map(fn {_name, address} -> address end)

    assert onboarded_email in recipients
    assert newcomer_email in recipients
  end

  # Drain the mailbox and keep only the "winner is decided" emails, ignoring the
  # confirmation emails produced while creating passwordless users.
  defp flush_result_emails do
    []
    |> flush_emails()
    |> Enum.filter(&(&1.subject == "Der Termin steht fest"))
  end

  defp flush_emails(acc) do
    receive do
      {:email, email} -> flush_emails([email | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
