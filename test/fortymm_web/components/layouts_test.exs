defmodule FortymmWeb.Components.LayoutsTest do
  use FortymmWeb.ConnCase, async: false

  import Fortymm.AccountsFixtures

  describe "Administration navigation link" do
    test "displays administration link for users with access_administration permission", %{
      conn: conn
    } do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      # Check desktop navigation
      assert html =~ ~s(href="/administration")
      assert html =~ "Administration"
      assert html =~ "hero-shield-check"
    end

    test "does not display administration link for regular users", %{conn: conn} do
      user = regular_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      # Administration link should not appear
      refute html =~ ~s(href="/administration")
      # But other navigation should still be present
      assert html =~ "Dashboard"
    end

    test "does not display administration link for users without roles", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      # Administration link should not appear
      refute html =~ ~s(href="/administration")
      assert html =~ "Dashboard"
    end

    test "displays administration link in mobile menu for admins", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      # Check that mobile menu contains administration link
      # The mobile menu is rendered but hidden by default
      assert html =~ ~s(id="mobile-menu")
      # Administration link appears in the mobile menu structure
      assert html =~ ~s(href="/administration")
    end

    test "administration link becomes active when on administration page", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration")

      html = html_response(conn, 200)

      # Check for active state class
      assert html =~ "menu-active"
      assert html =~ "Administration"
    end

    test "user gains access to link after being assigned administrator role", %{conn: _conn} do
      # Ensure admin role exists
      get_admin_role()

      user = regular_user_fixture()

      # Initially no administration link
      conn_before =
        build_conn()
        |> log_in_user(user)
        |> get(~p"/dashboard")

      html_before = html_response(conn_before, 200)
      refute html_before =~ ~s(href="/administration")

      # Assign admin role
      {:ok, _updated_user} = Fortymm.Accounts.assign_role(user, "administrator")

      # Now the link should appear
      conn_after =
        build_conn()
        |> log_in_user(Fortymm.Repo.get!(Fortymm.Accounts.User, user.id))
        |> get(~p"/dashboard")

      html_after = html_response(conn_after, 200)
      assert html_after =~ ~s(href="/administration")
      assert html_after =~ "Administration"
    end
  end

  describe "Navigation structure" do
    test "displays dashboard link for authenticated users", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      assert html =~ ~s(href="/dashboard")
      assert html =~ "Dashboard"
      assert html =~ "hero-home"
    end

    test "displays mobile menu toggle button for authenticated users", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/dashboard")

      html = html_response(conn, 200)

      assert html =~ ~s(id="mobile-menu-toggle")
      assert html =~ "hero-bars-3"
    end

    test "does not display navigation sidebar for unauthenticated users", %{conn: conn} do
      conn = get(conn, ~p"/")

      html = html_response(conn, 200)

      # Should not have the sidenav structure
      refute html =~ ~s(class="menu menu-lg)
    end
  end
end
