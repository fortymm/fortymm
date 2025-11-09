defmodule FortymmWeb.Administration.RoleControllerTest do
  use FortymmWeb.ConnCase, async: false

  import Fortymm.AccountsFixtures

  setup do
    # Create test roles
    role1 =
      role_fixture(%{name: "Administrator", description: "Full system administrator access"})

    role2 = role_fixture(%{name: "Moderator", description: "Content moderation permissions"})
    role3 = role_fixture(%{name: "User", description: "Standard user permissions"})

    # Create some permissions
    permission1 =
      permission_fixture(%{name: "Access Administration", slug: "access_administration"})

    permission2 = permission_fixture(%{name: "Moderate Content", slug: "moderate_content"})
    permission3 = permission_fixture(%{name: "View Reports", slug: "view_reports"})

    # Assign permissions to roles
    role1 = Fortymm.Repo.preload(role1, :permissions)

    {:ok, role1} =
      role1
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:permissions, [permission1, permission2, permission3])
      |> Fortymm.Repo.update()

    role2 = Fortymm.Repo.preload(role2, :permissions)

    {:ok, role2} =
      role2
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:permissions, [permission2])
      |> Fortymm.Repo.update()

    %{roles: [role1, role2, role3], permissions: [permission1, permission2, permission3]}
  end

  describe "GET /administration/roles" do
    test "renders roles list for administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "Role Management"
      assert html =~ "Manage and view all roles in the system"
    end

    test "displays roles table", %{conn: conn, roles: [role1, role2, role3]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ role1.name
      assert html =~ role2.name
      assert html =~ role3.name
      assert html =~ role1.description
      assert html =~ role2.description
      assert html =~ role3.description
    end

    test "displays role permissions", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ permission1.name
    end

    test "displays user count for each role", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      # Assign users to role1
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, _} = Fortymm.Accounts.assign_role(user1, role1.name)
      {:ok, _} = Fortymm.Accounts.assign_role(user2, role1.name)

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      # Check for user count icon
      assert html =~ "hero-user-group"
    end

    test "displays search form", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "Search"
      assert html =~ "Role name or description"
    end

    test "displays sortable column headers", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "ID"
      assert html =~ "Name"
      assert html =~ "Description"
      assert html =~ "Permissions"
      assert html =~ "Users"
      assert html =~ "Created"
    end

    test "displays pagination", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      assert html =~ "results"
    end

    test "displays shield icons for roles", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "hero-shield-check"
    end
  end

  describe "GET /administration/roles with filters" do
    test "filters by search term (name)", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=Administrator")

      html = html_response(conn, 200)
      assert html =~ role1.name
    end

    test "filters by search term (description)", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=system")

      html = html_response(conn, 200)
      assert html =~ role1.name
    end

    test "displays clear filter button when search is active", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=test")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "does not display clear filter button when search is empty", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "displays empty state when no roles match search", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=nonexistent")

      html = html_response(conn, 200)
      assert html =~ "No roles found"
      assert html =~ "Try adjusting your search"
    end
  end

  describe "GET /administration/roles with pagination" do
    test "paginates roles with page parameter", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough roles to trigger pagination
      for i <- 1..25 do
        role_fixture(%{name: "role#{i}", description: "Description #{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?page=2&per_page=10")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      # Should show results 11-20 out of total
      assert html =~ "11"
    end

    test "handles invalid page parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?page=invalid")

      # Should default to page 1
      assert html_response(conn, 200)
    end

    test "handles page less than 1", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?page=0")

      html = html_response(conn, 200)
      # Should show page 1
      assert html =~ "Showing"
    end

    test "displays pagination controls", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough roles for multiple pages
      for i <- 1..25 do
        role_fixture(%{name: "page_role#{i}", description: "Page description #{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "hero-chevron-left"
      assert html =~ "hero-chevron-right"
    end
  end

  describe "GET /administration/roles with sorting" do
    test "sorts by id ascending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=id&sort_order=asc")

      html = html_response(conn, 200)
      # Should show chevron-up for active ascending sort
      assert html =~ "hero-chevron-up"
    end

    test "sorts by id descending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=id&sort_order=desc")

      html = html_response(conn, 200)
      # Should show chevron-down for active descending sort
      assert html =~ "hero-chevron-down"
    end

    test "sorts by name", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=name&sort_order=asc")

      assert html_response(conn, 200)
    end

    test "sorts by description", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=description&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "sorts by inserted_at", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=inserted_at&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "handles invalid sort_by parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_by=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "handles invalid sort_order parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?sort_order=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "preserves search when sorting", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=Admin&sort_by=name&sort_order=asc")

      html = html_response(conn, 200)
      # Should maintain search filter in the form
      assert html =~ "Admin"
    end
  end

  describe "Authorization" do
    test "denies access to regular user", %{conn: conn} do
      user = regular_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/roles")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to user without role", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/roles")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/administration/roles")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      assert html_response(conn, 200) =~ "Role Management"
    end
  end

  describe "UI Components" do
    test "displays breadcrumb navigation", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "Breadcrumb"
      assert html =~ "Administration"
      assert html =~ "Roles"
      assert html =~ "/administration"
    end

    test "uses daisyUI card components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "card"
      assert html =~ "card-body"
    end

    test "uses daisyUI form components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "form-control"
      assert html =~ "input input-bordered"
    end

    test "uses daisyUI button components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "btn btn-primary"
    end

    test "uses daisyUI table components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "table table-zebra"
    end

    test "uses daisyUI badge components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "badge"
    end

    test "uses daisyUI join components for pagination", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough roles for pagination
      for i <- 1..25 do
        role_fixture(%{name: "join_role#{i}", description: "Join description #{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "join"
      assert html =~ "join-item"
    end
  end

  describe "Data Display" do
    test "displays role ID", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ Integer.to_string(role1.id)
    end

    test "displays formatted date", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      # Check for formatted date
      formatted_date = Calendar.strftime(role1.inserted_at, "%b %d, %Y")
      assert html =~ formatted_date
    end

    test "displays 'No description' for roles without description", %{conn: conn} do
      admin = admin_user_fixture()

      _role = role_fixture(%{name: "EmptyDescription", description: nil})

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "No description"
    end

    test "displays 'No permissions' for roles without permissions", %{conn: conn} do
      admin = admin_user_fixture()

      _role = role_fixture(%{name: "NoPermissions", description: "Test"})

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "No permissions"
    end

    test "shows limited permissions with count", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      # Add a 4th permission to role1
      permission4 = permission_fixture(%{name: "Extra Permission", slug: "extra_permission"})
      role1 = Fortymm.Repo.preload(role1, :permissions, force: true)

      {:ok, _role1} =
        role1
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, role1.permissions ++ [permission4])
        |> Fortymm.Repo.update()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      # Should show "+N more" for additional permissions
      assert html =~ "more"
    end

    test "displays user count correctly", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      # Assign 3 users to role1
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      {:ok, _} = Fortymm.Accounts.assign_role(user1, role1.name)
      {:ok, _} = Fortymm.Accounts.assign_role(user2, role1.name)
      {:ok, _} = Fortymm.Accounts.assign_role(user3, role1.name)

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles")

      html = html_response(conn, 200)
      assert html =~ "3"
    end
  end

  describe "Integration" do
    test "combines all features: search, sort, paginate", %{conn: conn} do
      admin = admin_user_fixture()

      # Create test roles
      for i <- 1..15 do
        role_fixture(%{name: "test_role#{i}", description: "Test description #{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(
          ~p"/administration/roles?search=test&sort_by=name&sort_order=asc&page=1&per_page=10"
        )

      html = html_response(conn, 200)
      assert html =~ "test"
      assert html =~ "Showing"
    end

    test "maintains state across navigation", %{conn: conn} do
      admin = admin_user_fixture()

      # Create roles for pagination
      for i <- 1..25 do
        role_fixture(%{name: "nav_role#{i}", description: "Nav description #{i}"})
      end

      # First request with filters
      conn1 =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/roles?search=nav&sort_by=name&sort_order=asc")

      html1 = html_response(conn1, 200)
      assert html1 =~ "nav"

      # Navigate to page 2 - filters should persist in pagination links
      assert html1 =~ "search=nav"
      assert html1 =~ "sort_by=name"
    end
  end
end
