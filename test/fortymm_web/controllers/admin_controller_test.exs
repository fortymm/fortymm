defmodule FortymmWeb.AdminControllerTest do
  use FortymmWeb.ConnCase, async: true

  import Fortymm.AccountsFixtures

  describe "GET /administration" do
    test "renders dashboard for administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "Administration Dashboard"
      assert html =~ "Manage your application settings and users"
    end

    test "displays user management card", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "User Management"
      assert html =~ "View and manage user accounts, roles, and permissions"
    end

    test "displays roles and permissions cards", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      # Check for Roles card
      assert html =~ "Roles"
      assert html =~ "Manage user roles and their associated permissions"
      assert html =~ "Manage Roles"
      # Check for Permissions card
      assert html =~ "Permissions"
      assert html =~ "Define and manage system permissions and capabilities"
    end

    test "displays system settings card", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "System Settings"
      assert html =~ "Configure application settings and preferences"
    end

    test "displays quick stats section", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "Quick Stats"
      assert html =~ "Total Users"
      assert html =~ "New Users (30d)"
      assert html =~ "Active Challenges"
    end

    test "displays administrator access alert", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "Administrator Access"
      assert html =~ "You have full administrative access to this application"
    end

    test "displays manage users link", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      assert html =~ "Manage Users"
      assert html =~ "/administration/users"
    end

    test "displays coming soon placeholders for permissions and system settings", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)
      # Permissions and System Settings still show Coming Soon
      assert html =~ "Coming Soon"
      assert html =~ "Coming soon"
    end
  end

  describe "Authorization" do
    test "denies access to regular user", %{conn: conn} do
      user = regular_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to user without role", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/administration")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to user who was assigned administrator role", %{conn: conn} do
      # Ensure admin role exists
      get_admin_role()

      user = regular_user_fixture()

      # Initially denied
      conn_denied =
        conn
        |> log_in_user(user)
        |> get(~p"/administration")

      assert redirected_to(conn_denied) == ~p"/dashboard"

      # Assign admin role
      {:ok, _updated_user} = Fortymm.Accounts.assign_role(user, "administrator")

      # Now allowed
      conn =
        conn
        |> log_in_user(Fortymm.Repo.get!(Fortymm.Accounts.User, user.id))
        |> get(~p"/administration")

      assert html_response(conn, 200) =~ "Administration Dashboard"
    end
  end

  describe "Layout and UI" do
    test "uses app layout", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      # Verify the layout renders properly
      html = html_response(conn, 200)
      assert html =~ "Administration Dashboard"
    end

    test "displays management cards in grid layout", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      # Check for grid classes
      html = html_response(conn, 200)
      assert html =~ "grid"
      assert html =~ "gap-6"
    end

    test "displays icons for each card", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      # Check for icon components
      html = html_response(conn, 200)
      assert html =~ "hero-users"
      assert html =~ "hero-shield-check"
      assert html =~ "hero-key"
      assert html =~ "hero-cog-6-tooth"
      assert html =~ "hero-chart-bar"
    end
  end
end
