defmodule FortymmWeb.Administration.UserControllerTest do
  use FortymmWeb.ConnCase, async: true

  import Fortymm.AccountsFixtures

  setup do
    # Create test roles
    role1 = role_fixture(%{name: "role1", description: "Role 1"})
    role2 = role_fixture(%{name: "role2", description: "Role 2"})

    # Create test users
    user1 = user_fixture(%{email: "alice@example.com", username: "alice"})
    user2 = user_fixture(%{email: "bob@example.com", username: "bob"})
    user3 = user_fixture(%{email: "charlie@example.com", username: "charlie"})

    {:ok, user1} = Fortymm.Accounts.assign_role(user1, role1.name)
    {:ok, user2} = Fortymm.Accounts.assign_role(user2, role2.name)

    %{users: [user1, user2, user3], roles: [role1, role2]}
  end

  describe "GET /administration/users" do
    test "renders users list for administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "User Management"
      assert html =~ "Manage and view all users in the system"
    end

    test "displays users table", %{conn: conn, users: [user1, user2, user3]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ user1.email
      assert html =~ user2.email
      assert html =~ user3.email
      assert html =~ user1.username
      assert html =~ user2.username
      assert html =~ user3.username
    end

    test "displays user roles", %{conn: conn, users: [_user1 | _], roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ role1.name
    end

    test "displays gravatar avatars", %{conn: conn, users: [_user1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      # Check for gravatar URL
      assert html =~ "gravatar.com/avatar"
    end

    test "displays user confirmation status", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Confirmed"
    end

    test "displays search form", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Search"
      assert html =~ "Email or username"
    end

    test "displays role filter", %{conn: conn, roles: [role1, role2]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Role"
      assert html =~ "All Roles"
      assert html =~ role1.name
      assert html =~ role2.name
    end

    test "displays sortable column headers", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "ID"
      assert html =~ "Username"
      assert html =~ "Email"
      assert html =~ "Status"
      assert html =~ "Created"
    end

    test "displays pagination", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      assert html =~ "results"
    end
  end

  describe "GET /administration/users with filters" do
    test "filters by search term", %{conn: conn, users: [user1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=alice")

      html = html_response(conn, 200)
      assert html =~ user1.email
    end

    test "filters by role", %{conn: conn, users: [user1 | _], roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?role_id=#{role1.id}")

      html = html_response(conn, 200)
      assert html =~ user1.email
    end

    test "displays clear filter button when filters are active", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=test")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "displays clear filter button when role filter is active", %{
      conn: conn,
      roles: [role1 | _]
    } do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?role_id=#{role1.id}")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "does not display clear filter button when search is empty", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "does not display clear filter button when role_id is empty", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?role_id=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "combines search and role filter", %{conn: conn, users: [user1 | _], roles: [role1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=alice&role_id=#{role1.id}")

      html = html_response(conn, 200)
      assert html =~ user1.email
    end

    test "displays empty state when no users match filters", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=nonexistent")

      html = html_response(conn, 200)
      assert html =~ "No users found"
      assert html =~ "Try adjusting your filters"
    end
  end

  describe "GET /administration/users with pagination" do
    test "paginates users with page parameter", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough users to trigger pagination
      for i <- 1..25 do
        user_fixture(%{email: "user#{i}@example.com", username: "user#{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?page=2&per_page=10")

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
        |> get(~p"/administration/users?page=invalid")

      # Should default to page 1
      assert html_response(conn, 200)
    end

    test "handles page less than 1", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?page=0")

      html = html_response(conn, 200)
      # Should show page 1
      assert html =~ "Showing"
    end

    test "displays pagination controls", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough users for multiple pages
      for i <- 1..25 do
        user_fixture(%{email: "page#{i}@example.com", username: "page#{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "hero-chevron-left"
      assert html =~ "hero-chevron-right"
    end
  end

  describe "GET /administration/users with sorting" do
    test "sorts by id ascending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=id&sort_order=asc")

      html = html_response(conn, 200)
      # Should show chevron-up for active ascending sort
      assert html =~ "hero-chevron-up"
    end

    test "sorts by id descending", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=id&sort_order=desc")

      html = html_response(conn, 200)
      # Should show chevron-down for active descending sort
      assert html =~ "hero-chevron-down"
    end

    test "sorts by email", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=email&sort_order=asc")

      assert html_response(conn, 200)
    end

    test "sorts by username", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=username&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "sorts by inserted_at", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=inserted_at&sort_order=desc")

      assert html_response(conn, 200)
    end

    test "handles invalid sort_by parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_by=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "handles invalid sort_order parameter", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?sort_order=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "preserves filters when sorting", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=alice&sort_by=email&sort_order=asc")

      html = html_response(conn, 200)
      # Should maintain search filter in the form
      assert html =~ "alice"
    end
  end

  describe "Authorization" do
    test "denies access to regular user", %{conn: conn} do
      user = regular_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/users")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to user without role", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/administration/users")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permission"
    end

    test "denies access to unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/administration/users")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to administrator", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      assert html_response(conn, 200) =~ "User Management"
    end
  end

  describe "UI Components" do
    test "displays breadcrumb navigation", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Breadcrumb"
      assert html =~ "Administration"
      assert html =~ "Users"
      assert html =~ "/administration"
    end

    test "uses daisyUI card components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "card"
      assert html =~ "card-body"
    end

    test "uses daisyUI form components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "form-control"
      assert html =~ "input input-bordered"
      assert html =~ "select select-bordered"
    end

    test "uses daisyUI button components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "btn btn-primary"
    end

    test "uses daisyUI table components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "table table-zebra"
    end

    test "uses daisyUI badge components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "badge"
    end

    test "uses daisyUI avatar components", %{conn: conn} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "avatar"
    end

    test "uses daisyUI join components for pagination", %{conn: conn} do
      admin = admin_user_fixture()

      # Create enough users for pagination
      for i <- 1..25 do
        user_fixture(%{email: "join#{i}@example.com", username: "join#{i}"})
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "join"
      assert html =~ "join-item"
    end
  end

  describe "Data Display" do
    test "displays user ID", %{conn: conn, users: [user1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ Integer.to_string(user1.id)
    end

    test "displays formatted date", %{conn: conn, users: [user1 | _]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      # Check for formatted date
      formatted_date = Calendar.strftime(user1.inserted_at, "%b %d, %Y")
      assert html =~ formatted_date
    end

    test "displays 'No Role' badge for users without roles", %{conn: conn, users: [_, _, _user3]} do
      admin = admin_user_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "No Role"
    end

    test "displays pending status for unconfirmed users", %{conn: conn} do
      admin = admin_user_fixture()

      _unconfirmed =
        unconfirmed_user_fixture(%{email: "pending@example.com", username: "pending"})

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users")

      html = html_response(conn, 200)
      assert html =~ "Pending"
    end
  end

  describe "Integration" do
    test "combines all features: search, filter, sort, paginate", %{
      conn: conn,
      roles: [role1 | _]
    } do
      admin = admin_user_fixture()

      # Create users with role1
      for i <- 1..15 do
        user = user_fixture(%{email: "test#{i}@example.com", username: "test#{i}"})
        {:ok, _} = Fortymm.Accounts.assign_role(user, role1.name)
      end

      conn =
        conn
        |> log_in_user(admin)
        |> get(
          ~p"/administration/users?search=test&role_id=#{role1.id}&sort_by=email&sort_order=asc&page=1&per_page=10"
        )

      html = html_response(conn, 200)
      assert html =~ "test"
      assert html =~ role1.name
      assert html =~ "Showing"
    end

    test "maintains state across navigation", %{conn: conn} do
      admin = admin_user_fixture()

      # Create users for pagination
      for i <- 1..25 do
        user_fixture(%{email: "nav#{i}@example.com", username: "nav#{i}"})
      end

      # First request with filters
      conn1 =
        conn
        |> log_in_user(admin)
        |> get(~p"/administration/users?search=nav&sort_by=email&sort_order=asc")

      html1 = html_response(conn1, 200)
      assert html1 =~ "nav"

      # Navigate to page 2 - filters should persist in pagination links
      assert html1 =~ "search=nav"
      assert html1 =~ "sort_by=email"
    end
  end
end
