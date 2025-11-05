# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Fortymm.Repo.insert!(%Fortymm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Fortymm.Repo
alias Fortymm.Accounts.{Role, Permission}
import Ecto.Query

# Helper function to create or update a role
defmodule Seeds do
  def upsert_role(name, description) do
    case Repo.get_by(Role, name: name) do
      nil ->
        %Role{}
        |> Role.changeset(%{name: name, description: description})
        |> Repo.insert!()
        |> IO.inspect(label: "Created role")

      role ->
        IO.puts("Role '#{name}' already exists")
        role
    end
  end

  def upsert_permission(name, slug, description) do
    case Repo.get_by(Permission, slug: slug) do
      nil ->
        %Permission{}
        |> Permission.changeset(%{name: name, slug: slug, description: description})
        |> Repo.insert!()
        |> IO.inspect(label: "Created permission")

      permission ->
        IO.puts("Permission '#{slug}' already exists")
        permission
    end
  end

  def assign_permissions_to_role(role, permission_slugs) do
    permissions =
      Enum.map(permission_slugs, fn slug ->
        Repo.get_by!(Permission, slug: slug)
      end)

    role = Repo.preload(role, :permissions)

    # Only add permissions that aren't already assigned
    existing_slugs = Enum.map(role.permissions, & &1.slug) |> MapSet.new()
    new_permissions = Enum.reject(permissions, fn p -> MapSet.member?(existing_slugs, p.slug) end)

    if Enum.any?(new_permissions) do
      role
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:permissions, role.permissions ++ new_permissions)
      |> Repo.update!()
      |> IO.inspect(label: "Updated permissions for role")
    else
      IO.puts("All permissions already assigned to role '#{role.name}'")
      role
    end
  end

  def assign_default_role_to_users do
    user_role = Repo.get_by!(Role, name: "user")

    # Find users without a role
    users_without_role =
      Fortymm.Accounts.User
      |> Ecto.Query.where([u], is_nil(u.role_id))
      |> Repo.all()

    count = length(users_without_role)

    if count > 0 do
      Enum.each(users_without_role, fn user ->
        user
        |> Ecto.Changeset.change(role_id: user_role.id)
        |> Repo.update!()
      end)

      IO.puts("Assigned default 'user' role to #{count} users")
    else
      IO.puts("All users already have roles assigned")
    end
  end
end

# Seed Roles
IO.puts("\n=== Seeding Roles ===")
user_role = Seeds.upsert_role("user", "Standard user with basic permissions")
admin_role = Seeds.upsert_role("administrator", "Administrator with full access")

# Seed Permissions
IO.puts("\n=== Seeding Permissions ===")

Seeds.upsert_permission(
  "Access Dashboard",
  "access_dashboard",
  "Can access the main dashboard"
)

Seeds.upsert_permission(
  "Access Administration",
  "access_administration",
  "Can access the administration panel"
)

Seeds.upsert_permission(
  "Manage Users",
  "manage_users",
  "Can manage user accounts"
)

Seeds.upsert_permission(
  "Manage Roles",
  "manage_roles",
  "Can manage roles and permissions"
)

# Assign permissions to roles
IO.puts("\n=== Assigning Permissions ===")
Seeds.assign_permissions_to_role(user_role, ["access_dashboard"])

Seeds.assign_permissions_to_role(admin_role, [
  "access_dashboard",
  "access_administration",
  "manage_users",
  "manage_roles"
])

# Assign default role to existing users
IO.puts("\n=== Assigning Default Roles to Users ===")
Seeds.assign_default_role_to_users()

IO.puts("\n=== Seeding complete! ===")
