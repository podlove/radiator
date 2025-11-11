Radiator.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "bob@radiator.de",
  password: "supersupersecret",
  password_confirmation: "supersupersecret"
})
|> Ash.create!(authorize?: false)

Radiator.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "jim@radiator.de",
  password: "supersupersecret",
  password_confirmation: "supersupersecret"
})
|> Ash.create!(authorize?: false)
