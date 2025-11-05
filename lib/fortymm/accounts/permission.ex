defmodule Fortymm.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :description, :string

    many_to_many :roles, Fortymm.Accounts.Role, join_through: "role_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:slug, min: 2, max: 50)
    |> validate_format(:slug, ~r/^[a-z_]+$/, message: "must be lowercase with underscores only")
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
