defmodule Fortymm.Administration.UsersTest do
  use Fortymm.DataCase

  alias Fortymm.AccountsFixtures
  alias Fortymm.Administration.Users

  describe "list_users/1" do
    setup do
      # Create some test roles
      role1 = AccountsFixtures.role_fixture(%{name: "role1"})
      role2 = AccountsFixtures.role_fixture(%{name: "role2"})

      # Create users with different attributes
      user1 =
        AccountsFixtures.user_fixture(%{
          email: "alice@example.com",
          username: "alice"
        })

      {:ok, user1} = Fortymm.Accounts.assign_role(user1, role1.name)

      user2 =
        AccountsFixtures.user_fixture(%{
          email: "bob@example.com",
          username: "bob"
        })

      {:ok, user2} = Fortymm.Accounts.assign_role(user2, role2.name)

      user3 =
        AccountsFixtures.user_fixture(%{
          email: "charlie@example.com",
          username: "charlie"
        })

      # Leave user3 without a role

      # Create an unconfirmed user
      user4 =
        AccountsFixtures.unconfirmed_user_fixture(%{
          email: "david@example.com",
          username: "david"
        })

      %{users: [user1, user2, user3, user4], roles: [role1, role2]}
    end

    test "returns all users by default", %{users: _users} do
      result = Users.list_users()

      assert length(result.users) >= 4
      assert result.total >= 4
      assert result.page == 1
      assert result.per_page == 20
      assert result.total_pages >= 1
    end

    test "paginates users correctly" do
      # Create 25 users to test pagination
      for i <- 1..25 do
        AccountsFixtures.user_fixture(%{
          email: "user#{i}@example.com",
          username: "user#{i}"
        })
      end

      # First page with 10 per page
      result1 = Users.list_users(page: 1, per_page: 10)
      assert length(result1.users) == 10
      assert result1.page == 1
      assert result1.per_page == 10
      assert result1.total >= 25

      # Second page
      result2 = Users.list_users(page: 2, per_page: 10)
      assert length(result2.users) == 10
      assert result2.page == 2

      # Last page
      last_page = result1.total_pages
      result3 = Users.list_users(page: last_page, per_page: 10)
      assert result3.page == last_page
      assert length(result3.users) > 0
    end

    test "filters users by search term (email)", %{users: [user1 | _]} do
      result = Users.list_users(search: "alice@example")

      assert length(result.users) == 1
      assert hd(result.users).email == user1.email
    end

    test "filters users by search term (username)", %{users: [_, user2 | _]} do
      result = Users.list_users(search: "bob")

      assert length(result.users) == 1
      assert hd(result.users).username == user2.username
    end

    test "search is case-insensitive" do
      result = Users.list_users(search: "ALICE")

      assert length(result.users) >= 1
      assert Enum.any?(result.users, &(&1.username == "alice"))
    end

    test "filters users by role_id", %{users: [user1 | _], roles: [role1 | _]} do
      result = Users.list_users(role_id: role1.id)

      assert length(result.users) == 1
      assert hd(result.users).id == user1.id
      assert hd(result.users).role_id == role1.id
    end

    test "filters users by role_id as string", %{users: [user1 | _], roles: [role1 | _]} do
      result = Users.list_users(role_id: Integer.to_string(role1.id))

      assert length(result.users) == 1
      assert hd(result.users).id == user1.id
    end

    test "handles invalid role_id string gracefully" do
      result = Users.list_users(role_id: "invalid")

      # Should return all users when role_id is invalid
      assert result.total >= 4
    end

    test "sorts users by id ascending", %{users: [_user1, _user2 | _]} do
      result = Users.list_users(sort_by: :id, sort_order: :asc)

      user_ids = Enum.map(result.users, & &1.id)
      assert user_ids == Enum.sort(user_ids)
    end

    test "sorts users by id descending", %{users: [_user1, _user2 | _]} do
      result = Users.list_users(sort_by: :id, sort_order: :desc)

      user_ids = Enum.map(result.users, & &1.id)
      assert user_ids == Enum.sort(user_ids, :desc)
    end

    test "sorts users by email ascending" do
      result = Users.list_users(sort_by: :email, sort_order: :asc)

      emails = Enum.map(result.users, & &1.email)
      assert emails == Enum.sort(emails)
    end

    test "sorts users by username descending" do
      result = Users.list_users(sort_by: :username, sort_order: :desc)

      usernames = Enum.map(result.users, & &1.username)
      assert usernames == Enum.sort(usernames, :desc)
    end

    test "sorts users by inserted_at descending by default" do
      result = Users.list_users()

      inserted_ats = Enum.map(result.users, & &1.inserted_at)

      assert inserted_ats ==
               Enum.sort(inserted_ats, fn a, b ->
                 DateTime.compare(a, b) in [:gt, :eq]
               end)
    end

    test "combines search and role filter" do
      AccountsFixtures.user_fixture(%{email: "search@example.com", username: "searchuser"})

      result = Users.list_users(search: "search", role_id: 999_999)

      # Should apply both filters
      assert result.total == 0
    end

    test "combines search, role filter, and sorting" do
      role = AccountsFixtures.role_fixture(%{name: "test_role"})

      user1 =
        AccountsFixtures.user_fixture(%{email: "test1@example.com", username: "test1user"})

      user2 =
        AccountsFixtures.user_fixture(%{email: "test2@example.com", username: "test2user"})

      {:ok, _user1} = Fortymm.Accounts.assign_role(user1, role.name)
      {:ok, _user2} = Fortymm.Accounts.assign_role(user2, role.name)

      result =
        Users.list_users(search: "test", role_id: role.id, sort_by: :email, sort_order: :asc)

      assert length(result.users) == 2
      assert hd(result.users).email == "test1@example.com"
    end

    test "handles empty search term" do
      result1 = Users.list_users(search: "")
      result2 = Users.list_users(search: nil)

      # Both should return all users
      assert result1.total == result2.total
    end

    test "handles empty role_id" do
      result1 = Users.list_users(role_id: "")
      result2 = Users.list_users(role_id: nil)

      # Both should return all users
      assert result1.total == result2.total
    end

    test "handles page less than 1" do
      result = Users.list_users(page: 0)

      # Should default to page 1
      assert result.page == 1
    end

    test "handles invalid sort_by field" do
      result = Users.list_users(sort_by: :invalid_field)

      # Should still return results with default sorting
      assert result.total >= 4
    end

    test "handles invalid sort_order" do
      result = Users.list_users(sort_order: :invalid)

      # Should still return results
      assert result.total >= 4
    end

    test "preloads role association" do
      result = Users.list_users()

      user_with_role = Enum.find(result.users, & &1.role)

      assert user_with_role.role != nil
      assert %Fortymm.Accounts.Role{} = user_with_role.role
    end

    test "calculates total_pages correctly" do
      # Create exactly 25 users
      for i <- 1..25 do
        AccountsFixtures.user_fixture(%{
          email: "paging#{i}@example.com",
          username: "paging#{i}"
        })
      end

      result = Users.list_users(per_page: 10)
      total = result.total

      expected_pages = ceil(total / 10)
      assert result.total_pages == expected_pages
    end

    test "returns correct offset for pagination" do
      # Create 30 users
      for i <- 1..30 do
        AccountsFixtures.user_fixture(%{
          email: "offset#{i}@example.com",
          username: "offset#{i}"
        })
      end

      page1 = Users.list_users(page: 1, per_page: 10, sort_by: :id, sort_order: :asc)
      page2 = Users.list_users(page: 2, per_page: 10, sort_by: :id, sort_order: :asc)

      # Ensure page 2 users are different from page 1
      page1_ids = Enum.map(page1.users, & &1.id)
      page2_ids = Enum.map(page2.users, & &1.id)

      assert MapSet.disjoint?(MapSet.new(page1_ids), MapSet.new(page2_ids))
    end
  end

  describe "get_user/1" do
    test "returns user with preloaded role" do
      role = AccountsFixtures.role_fixture(%{name: "test_role"})
      user = AccountsFixtures.user_fixture()
      {:ok, user} = Fortymm.Accounts.assign_role(user, role.name)

      result = Users.get_user(user.id)

      assert result.id == user.id
      assert result.role.id == role.id
    end

    test "returns nil for non-existent user" do
      result = Users.get_user(999_999_999)

      assert result == nil
    end

    test "returns user without role" do
      user = AccountsFixtures.user_fixture()

      result = Users.get_user(user.id)

      assert result.id == user.id
      assert result.role == nil
    end
  end

  describe "get_user!/1" do
    test "returns user with preloaded role" do
      role = AccountsFixtures.role_fixture(%{name: "test_role"})
      user = AccountsFixtures.user_fixture()
      {:ok, user} = Fortymm.Accounts.assign_role(user, role.name)

      result = Users.get_user!(user.id)

      assert result.id == user.id
      assert result.role.id == role.id
    end

    test "raises for non-existent user" do
      assert_raise Ecto.NoResultsError, fn ->
        Users.get_user!(999_999_999)
      end
    end
  end

  describe "list_roles/0" do
    test "returns all roles sorted by name" do
      # Clear existing roles first
      Fortymm.Repo.delete_all(Fortymm.Accounts.Role)

      _role_c = AccountsFixtures.role_fixture(%{name: "c_role"})
      _role_a = AccountsFixtures.role_fixture(%{name: "a_role"})
      _role_b = AccountsFixtures.role_fixture(%{name: "b_role"})

      result = Users.list_roles()

      assert length(result) == 3
      assert Enum.map(result, & &1.name) == ["a_role", "b_role", "c_role"]
    end

    test "returns empty list when no roles exist" do
      Fortymm.Repo.delete_all(Fortymm.Accounts.Role)

      result = Users.list_roles()

      assert result == []
    end
  end
end
