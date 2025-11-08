defmodule Fortymm.Accounts.Role do
  @moduledoc """
  Represents a user role in the system.

  Roles define sets of permissions that can be assigned to users.
  Each role has a unique name and can be associated with multiple permissions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :description, :string

    many_to_many :permissions, Fortymm.Accounts.Permission, join_through: "role_permissions"
    has_many :users, Fortymm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint(:name)
  end
end
