defmodule Radiator.Accounts.WebAuthnCredential do
  @moduledoc false

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "web_authn_credentials"
    repo Radiator.Repo

    policies do
      bypass AshAuthentication.Checks.AshAuthenticationInteraction do
        authorize_if always()
      end
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:credential_id, :public_key, :sign_count, :label, :user_id]
    end

    update :update do
      primary? true
      accept [:sign_count, :label, :last_used_at]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :credential_id, :binary do
      allow_nil? false
    end

    attribute :sign_count, :integer
    attribute :label, :string
    attribute :last_used_at, :utc_datetime_usec

    attribute :public_key, AshAuthentication.Strategy.WebAuthn.CoseKey do
      allow_nil? false
      public? true
    end
  end

  relationships do
    belongs_to :user, Radiator.Accounts.User do
      allow_nil? false
    end
  end

  identities do
    identity :unique_credential_id, [:credential_id]
  end
end
