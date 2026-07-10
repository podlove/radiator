defmodule Radiator.Accounts.User.Senders.SendVotingResultTest do
  use Radiator.DataCase, async: true

  import Radiator.Generator
  import Swoosh.TestAssertions

  alias Radiator.Accounts.User
  alias Radiator.Accounts.User.Senders.SendVotingResult
  alias Radiator.Podcasts.Episode.Scheduling

  # 2026-04-18 is a Saturday -> "Sa".
  @saturday ~U[2026-04-18 22:00:00Z]

  test "sends the winning datetime and a magic-link deep link to the user" do
    podcast = generate(podcast())
    episode = generate(episode(%{podcast_id: podcast.id}))
    owner = seed_user()
    recipient = seed_user()

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        proposed_datetimes: [@saturday]
      })
      |> Ash.create(authorize?: false)

    [proposal] = scheduling.proposals

    {:ok, _closed} =
      scheduling
      |> Ash.Changeset.for_update(:finalize, %{
        chosen_proposal_id: proposal.id,
        user_id: owner.id
      })
      |> Ash.update(authorize?: false)

    episode = Ash.load!(episode, [:scheduling], authorize?: false)

    SendVotingResult.send(recipient, episode)

    return_to = URI.encode_www_form("/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

    assert_email_sent(fn mail ->
      assert mail.subject == "Der Termin steht fest"
      assert mail.from == {"Radiator: No Reply", "noreply@radiator.metaebene.net"}
      assert mail.to == [{"", to_string(recipient.email)}]
      assert mail.html_body =~ "Sa 18.04.2026, 22:00"
      assert mail.html_body =~ "/auth/user/magic_link?token="
      assert mail.html_body =~ "return_to=#{return_to}"
    end)
  end

  test "HTML-escapes the episode title in the body" do
    podcast = generate(podcast())
    episode = generate(episode(%{podcast_id: podcast.id, title: "Bits & <b>Bäume</b>"}))
    owner = seed_user()
    recipient = seed_user()

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        proposed_datetimes: [@saturday]
      })
      |> Ash.create(authorize?: false)

    [proposal] = scheduling.proposals

    {:ok, _closed} =
      scheduling
      |> Ash.Changeset.for_update(:finalize, %{
        chosen_proposal_id: proposal.id,
        user_id: owner.id
      })
      |> Ash.update(authorize?: false)

    episode = Ash.load!(episode, [:scheduling], authorize?: false)

    SendVotingResult.send(recipient, episode)

    assert_email_sent(fn mail ->
      refute mail.html_body =~ "<b>Bäume</b>"
      assert mail.html_body =~ "Bits &amp; &lt;b&gt;Bäume&lt;/b&gt;"
    end)
  end

  defp seed_user do
    email = "user_#{System.unique_integer([:positive])}@example.com"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("supersupersecret")
    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})
  end
end
