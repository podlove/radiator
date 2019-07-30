# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Radiator.Repo.insert!(%Radiator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Radiator.Repo
alias Radiator.Auth.Register
alias Radiator.Directory.Editor
alias Radiator.Contribution.Role

if Mix.env() != :test do
  {:ok, user} =
    Register.create_user(%{
      name: "admin",
      email: "admin@example.com",
      display_name: "admin",
      password: "password",
      status: :active
    })

  {:ok, foo} =
    Register.create_user(%{
      name: "foo",
      email: "foo@bar.local",
      display_name: "foobar",
      password: "pass",
      status: :active
    })

  Editor.create_network(user, %{
    title: "ACME"
  })

  {:ok, network2} =
    Editor.create_network(user, %{
      title: "BCME"
    })

  Editor.Permission.set_permission(foo, network2, :readonly)
end
