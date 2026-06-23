defmodule Radiator.People do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Radiator.People.Person do
      define :read_persons, action: :read
      define :create_person, action: :create
    end
  end
end
