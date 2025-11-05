defmodule FortymmWeb.Plugs.RequirePermissionTest do
  use FortymmWeb.ConnCase, async: true

  import Fortymm.AccountsFixtures

  alias FortymmWeb.Plugs.RequirePermission

  describe "init/1" do
    test "returns the permission slug" do
      assert RequirePermission.init("access_administration") == "access_administration"
    end

    test "returns list of permission slugs" do
      permissions = ["access_administration", "manage_users"]
      assert RequirePermission.init(permissions) == permissions
    end
  end

  describe "integration with controller routing" do
    test "admin can access administration dashboard" do
      admin = admin_user_fixture()

      conn =
        build_conn()
        |> log_in_user(admin)
        |> get(~p"/administration")

      assert html_response(conn, 200) =~ "Administration Dashboard"
    end

    test "regular user cannot access administration dashboard" do
      user = regular_user_fixture()

      conn =
        build_conn()
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "user without role cannot access administration dashboard" do
      user = user_fixture()

      conn =
        build_conn()
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "unauthenticated user is redirected to login" do
      conn =
        build_conn()
        |> get(~p"/administration")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to user who was assigned administrator role" do
      # Ensure admin role exists
      get_admin_role()

      user = regular_user_fixture()

      # Initially denied
      conn_denied =
        build_conn()
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn_denied) == ~p"/dashboard"

      # Assign admin role
      {:ok, _updated_user} = Fortymm.Accounts.assign_role(user, "administrator")

      # Now allowed
      conn =
        build_conn()
        |> log_in_user(Fortymm.Repo.get!(Fortymm.Accounts.User, user.id))
        |> get(~p"/administration")

      assert html_response(conn, 200) =~ "Administration Dashboard"
    end
  end
end
