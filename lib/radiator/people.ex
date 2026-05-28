defmodule Radiator.People do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

  resources do
    resource Radiator.People.Person do
      define :read_persons, action: :read
      define :create_person, action: :create
    end

    resource Radiator.People.Persona do
      define :read_personas, action: :read
      define :create_persona, action: :create
      define :get_by_user, action: :by_user, args: [:user_id]
    end
  end
end
