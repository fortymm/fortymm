defmodule FortymmWeb.Administration.PermissionControllerTest do
  use FortymmWeb.ConnCase, async: false

  import Fortymm.AccountsFixtures

  # Helper to convert numbers to slug-safe strings (only lowercase letters and underscores)
  # Maps numbers to letter-only strings
  @num_to_letters %{
    1 => "one",
    2 => "two",
    3 => "three",
    4 => "four",
    5 => "five",
    6 => "six",
    7 => "seven",
    8 => "eight",
    9 => "nine",
    10 => "ten",
    11 => "eleven",
    12 => "twelve",
    13 => "thirteen",
    14 => "fourteen",
    15 => "fifteen",
    16 => "sixteen",
    17 => "seventeen",
    18 => "eighteen",
    19 => "nineteen",
    20 => "twenty",
    21 => "twentyone",
    22 => "twentytwo",
    23 => "twentythree",
    24 => "twentyfour",
    25 => "twentyfive"
  }

  defp to_slug_part(i), do: @num_to_letters[i]

  setup do
    # Create test permissions
    permission1 =
      permission_fixture(%{
        name: "Access Administration",
        slug: "access_administration",
        description: "Full access to administration panel"
      })

    permission2 =
      permission_fixture(%{
        name: "Moderate Content",
        slug: "moderate_content",
        description: "Ability to moderate user content"
      })

    permission3 =
      permission_fixture(%{
        name: "View Reports",
        slug: "view_reports",
        description: "Access to system reports"
      })

    # Create test roles
    role1 = role_fixture(%{name: "Administrator", description: "Full system access"})
    role2 = role_fixture(%{name: "Moderator", description: "Content moderation"})

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

    %{
      permissions: [permission1, permission2, permission3],
      roles: [role1, role2]
    }
  end

  describe "GET /administration/permissions" do
    test "renders permissions list for administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "Permission Management"
      assert html =~ "Manage and view all permissions in the system"
    end

    test "displays permissions table", %{
      conn: conn,
      permissions: [permission1, permission2, permission3]
    } do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ permission1.name
      assert html =~ permission2.name
      assert html =~ permission3.name
      assert html =~ permission1.slug
      assert html =~ permission2.slug
      assert html =~ permission3.slug
    end

    test "displays permission descriptions", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ permission1.description
    end

    test "displays roles assigned to permissions", %{conn: conn, roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ role1.name
    end

    test "displays search form", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "Search"
      assert html =~ "Name, slug, or description"
    end

    test "displays sortable column headers", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "ID"
      assert html =~ "Name"
      assert html =~ "Slug"
      assert html =~ "Description"
      assert html =~ "Roles"
      assert html =~ "Created"
    end

    test "displays pagination", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      assert html =~ "results"
    end

    test "displays empty state message when no permissions exist", %{conn: conn} do
      admin = admin_user_fixture()

      # Search for non-existent permission to trigger empty state
      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=nonexistent_permission_xyz")

      html = html_response(conn, 200)
      assert html =~ "No permissions found"
    end
  end

  describe "GET /administration/permissions with filters" do
    test "filters by search term (name)", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=Access")

      html = html_response(conn, 200)
      assert html =~ permission1.name
    end

    test "filters by search term (slug)", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=access_administration")

      html = html_response(conn, 200)
      assert html =~ permission1.slug
    end

    test "filters by search term (description)", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=administration")

      html = html_response(conn, 200)
      assert html =~ permission1.name
    end

    test "displays clear filter button when search is active", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=test")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "does not display clear filter button when search is empty", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "displays empty state when no permissions match search", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=nonexistent")

      html = html_response(conn, 200)
      assert html =~ "No permissions found"
      assert html =~ "Try adjusting your search"
    end
  end

  describe "GET /administration/permissions with pagination" do
    test "paginates permissions with page parameter", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough permissions to trigger pagination
      for i <- 1..25 do
        slug = "permission_slug_" <> to_slug_part(i)

        permission_fixture(%{
          name: "permission#{i}",
          slug: slug,
          description: "Description #{i}"
        })
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?page=2&per_page=10")

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
        |> get(~p"/administration/permissions?page=invalid")

      # Should default to page 1
      assert html_response(conn, 200)
    end

    test "handles page less than 1", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?page=0")

      html = html_response(conn, 200)
      # Should show page 1
      assert html =~ "Showing"
    end

    test "displays pagination controls", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough permissions for multiple pages
      for i <- 1..25 do
        slug = "page_perm_" <> to_slug_part(i)

        permission_fixture(%{
          name: "page_permission#{i}",
          slug: slug,
          description: "Page description #{i}"
        })
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "hero-chevron-left"
      assert html =~ "hero-chevron-right"
    end
  end

  describe "GET /administration/permissions with sorting" do
    test "sorts by id ascending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=id&sort_order=asc")

      html = html_response(conn, 200)
      # Should show chevron-up for active ascending sort
      assert html =~ "hero-chevron-up"
    end

    test "sorts by id descending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=id&sort_order=desc")

      html = html_response(conn, 200)
      # Should show chevron-down for active descending sort
      assert html =~ "hero-chevron-down"
    end

    test "sorts by name", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=name&sort_order=asc")

      assert html_response(conn, 200)
    end

    test "sorts by slug", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=slug&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "sorts by inserted_at", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=inserted_at&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "handles invalid sort_by parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_by=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "handles invalid sort_order parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?sort_order=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "preserves search when sorting", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=Access&sort_by=name&sort_order=asc")

      html = html_response(conn, 200)
      # Should maintain search filter in the form
      assert html =~ "Access"
    end
  end

  describe "Authorization" do
    test "denies access to regular user", %{conn: conn} do
      user = regular_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/permissions")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to user without role", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/permissions")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/administration/permissions")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      assert html_response(conn, 200) =~ "Permission Management"
    end
  end

  describe "UI Components" do
    test "uses daisyUI card components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "card"
      assert html =~ "card-body"
    end

    test "uses daisyUI form components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "form-control"
      assert html =~ "input input-bordered"
    end

    test "uses daisyUI button components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "btn btn-primary"
    end

    test "uses daisyUI table components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "table table-zebra"
    end

    test "uses daisyUI badge components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "badge"
    end

    test "uses daisyUI join components for pagination", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough permissions for pagination
      for i <- 1..25 do
        slug = "join_perm_" <> to_slug_part(i)

        permission_fixture(%{
          name: "join_permission#{i}",
          slug: slug,
          description: "Join description #{i}"
        })
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "join"
      assert html =~ "join-item"
    end
  end

  describe "Data Display" do
    test "displays permission ID", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ Integer.to_string(permission1.id)
    end

    test "displays formatted date", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      # Check for formatted date
      formatted_date = Calendar.strftime(permission1.inserted_at, "%b %d, %Y")
      assert html =~ formatted_date
    end

    test "displays 'No description' for permissions without description", %{conn: conn} do
      admin = admin_user_fixture()

      _permission =
        permission_fixture(%{
          name: "EmptyDescription",
          slug: "empty_description",
          description: nil
        })

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "No description"
    end

    test "displays 'No roles' for permissions without roles", %{conn: conn} do
      admin = admin_user_fixture()

      _permission =
        permission_fixture(%{name: "NoRoles", slug: "no_roles", description: "Test"})

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      assert html =~ "No roles"
    end

    test "displays slug in code format", %{conn: conn, permissions: [permission1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      # Check for code tag
      assert html =~ "<code"
      assert html =~ permission1.slug
    end

    test "displays multiple roles as badges", %{conn: conn, roles: [role1, role2]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions")

      html = html_response(conn, 200)
      # Moderate Content permission should show both roles
      assert html =~ role1.name
      assert html =~ role2.name
    end
  end

  describe "Integration" do
    test "combines all features: search, sort, paginate", %{conn: conn} do
      admin = admin_user_fixture()

      # Create test permissions
      for i <- 1..15 do
        slug = "test_perm_" <> to_slug_part(i)

        permission_fixture(%{
          name: "test_permission#{i}",
          slug: slug,
          description: "Test description #{i}"
        })
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(
          ~p"/administration/permissions?search=test&sort_by=name&sort_order=asc&page=1&per_page=10"
        )

      html = html_response(conn, 200)
      assert html =~ "test"
      assert html =~ "Showing"
    end

    test "maintains state across navigation", %{conn: conn} do
      admin = admin_user_fixture()

      # Create permissions for pagination
      for i <- 1..25 do
        slug = "nav_perm_" <> to_slug_part(i)

        permission_fixture(%{
          name: "nav_permission#{i}",
          slug: slug,
          description: "Nav description #{i}"
        })
      end

      # First request with filters
      conn1 =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/permissions?search=nav&sort_by=name&sort_order=asc")

      html1 = html_response(conn1, 200)
      assert html1 =~ "nav"

      # Navigate to page 2 - filters should persist in pagination links
      assert html1 =~ "search=nav"
      assert html1 =~ "sort_by=name"
    end
  end
end
