defmodule Fortymm.Administration.Users.User do
  @moduledoc """
  Administration view of User for listing and managing users.
  This schema references the same users table but provides an
  administration-focused interface.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "users" do
    field :email, :string
    field :username, :string
    field :confirmed_at, :utc_datetime
    field :hashed_password, :string, redact: true

    belongs_to :role, Fortymm.Accounts.Role

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for administrative user updates.
  This is intentionally limited to fields that administrators should be able to modify.
  """
  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :role_id])
    |> validate_required([:email, :username])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
