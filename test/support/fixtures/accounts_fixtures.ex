defmodule Fortymm.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fortymm.Accounts` context.
  """

  import Ecto.Query

  alias Fortymm.Accounts
  alias Fortymm.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def unique_user_username do
    # Generate a unique username that meets the requirements:
    # - 3-20 characters
    # - Only lowercase letters, numbers, underscores, periods
    # - Cannot start/end with underscore or period
    # - No consecutive separators
    "user#{abs(System.unique_integer([:positive])) |> rem(1_000_000)}"
  end

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: unique_user_username()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Fortymm.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Fortymm.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Fortymm.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  ## Role fixtures

  def role_fixture(attrs \\ %{}) do
    name = Map.get(attrs, :name, "test_role_#{System.unique_integer([:positive])}")

    {:ok, role} =
      %Fortymm.Accounts.Role{}
      |> Fortymm.Accounts.Role.changeset(%{
        name: name,
        description: Map.get(attrs, :description, "Test role")
      })
      |> Fortymm.Repo.insert()

    role
  end

  def get_user_role do
    case Fortymm.Repo.get_by(Fortymm.Accounts.Role, name: "user") do
      nil ->
        role = role_fixture(%{name: "user", description: "Standard user with basic permissions"})
        # Assign access_dashboard permission
        permission =
          get_or_create_permission(
            "access_dashboard",
            "Access Dashboard",
            "Can access the main dashboard"
          )

        role
        |> Fortymm.Repo.preload(:permissions)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, [permission])
        |> Fortymm.Repo.update!()

      role ->
        role
    end
  end

  def get_admin_role do
    case Fortymm.Repo.get_by(Fortymm.Accounts.Role, name: "administrator") do
      nil ->
        role =
          role_fixture(%{name: "administrator", description: "Administrator with full access"})

        # Assign all permissions
        permissions = [
          get_or_create_permission(
            "access_dashboard",
            "Access Dashboard",
            "Can access the main dashboard"
          ),
          get_or_create_permission(
            "access_administration",
            "Access Administration",
            "Can access the administration panel"
          ),
          get_or_create_permission("manage_users", "Manage Users", "Can manage user accounts"),
          get_or_create_permission(
            "manage_roles",
            "Manage Roles",
            "Can manage roles and permissions"
          )
        ]

        role
        |> Fortymm.Repo.preload(:permissions)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, permissions)
        |> Fortymm.Repo.update!()

      role ->
        role
    end
  end

  defp get_or_create_permission(slug, name, description) do
    case Fortymm.Repo.get_by(Fortymm.Accounts.Permission, slug: slug) do
      nil -> permission_fixture(%{slug: slug, name: name, description: description})
      permission -> permission
    end
  end

  ## Permission fixtures

  def permission_fixture(attrs \\ %{}) do
    slug = Map.get(attrs, :slug, "test_permission_#{System.unique_integer([:positive])}")
    name = Map.get(attrs, :name, String.replace(slug, "_", " ") |> String.capitalize())

    {:ok, permission} =
      %Fortymm.Accounts.Permission{}
      |> Fortymm.Accounts.Permission.changeset(%{
        name: name,
        slug: slug,
        description: Map.get(attrs, :description, "Test permission")
      })
      |> Fortymm.Repo.insert()

    permission
  end

  def get_access_dashboard_permission do
    get_or_create_permission(
      "access_dashboard",
      "Access Dashboard",
      "Can access the main dashboard"
    )
  end

  def get_access_administration_permission do
    get_or_create_permission(
      "access_administration",
      "Access Administration",
      "Can access the administration panel"
    )
  end

  ## User with role fixtures

  def user_with_role_fixture(role_name, attrs \\ %{}) do
    # Ensure role exists first
    case role_name do
      "administrator" -> get_admin_role()
      "user" -> get_user_role()
      _ -> :ok
    end

    user = user_fixture(attrs)
    {:ok, user} = Accounts.assign_role(user, role_name)
    user
  end

  def admin_user_fixture(attrs \\ %{}) do
    user_with_role_fixture("administrator", attrs)
  end

  def regular_user_fixture(attrs \\ %{}) do
    user_with_role_fixture("user", attrs)
  end
end
