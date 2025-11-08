defmodule Fortymm.Administration.RolesTest do
  use Fortymm.DataCase

  alias Fortymm.AccountsFixtures
  alias Fortymm.Administration.Roles

  describe "list_roles/1" do
    setup do
      # Create some test roles
      role1 =
        AccountsFixtures.role_fixture(%{
          name: "Administrator",
          description: "Full system access"
        })

      role2 =
        AccountsFixtures.role_fixture(%{
          name: "Moderator",
          description: "Moderate content"
        })

      role3 =
        AccountsFixtures.role_fixture(%{
          name: "User",
          description: "Basic user access"
        })

      # Create some permissions
      permission1 =
        AccountsFixtures.permission_fixture(%{
          name: "Access Administration",
          slug: "access_administration"
        })

      permission2 =
        AccountsFixtures.permission_fixture(%{name: "Moderate Content", slug: "moderate_content"})

      # Assign permissions to roles
      role1 = Fortymm.Repo.preload(role1, :permissions)

      {:ok, role1} =
        role1
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, [permission1, permission2])
        |> Fortymm.Repo.update()

      role2 = Fortymm.Repo.preload(role2, :permissions)

      {:ok, role2} =
        role2
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, [permission2])
        |> Fortymm.Repo.update()

      %{roles: [role1, role2, role3], permissions: [permission1, permission2]}
    end

    test "returns all roles by default", %{roles: _roles} do
      result = Roles.list_roles()

      assert length(result.roles) >= 3
      assert result.total >= 3
      assert result.page == 1
      assert result.per_page == 20
      assert result.total_pages >= 1
    end

    test "paginates roles correctly" do
      # Create 25 roles to test pagination
      for i <- 1..25 do
        AccountsFixtures.role_fixture(%{
          name: "role#{i}",
          description: "Description #{i}"
        })
      end

      # First page with 10 per page
      result1 = Roles.list_roles(page: 1, per_page: 10)
      assert length(result1.roles) == 10
      assert result1.page == 1
      assert result1.per_page == 10
      assert result1.total >= 25

      # Second page
      result2 = Roles.list_roles(page: 2, per_page: 10)
      assert length(result2.roles) == 10
      assert result2.page == 2

      # Last page
      last_page = result1.total_pages
      result3 = Roles.list_roles(page: last_page, per_page: 10)
      assert result3.page == last_page
      assert length(result3.roles) > 0
    end

    test "filters roles by search term (name)", %{roles: [role1 | _]} do
      result = Roles.list_roles(search: "Administrator")

      assert length(result.roles) == 1
      assert hd(result.roles).name == role1.name
    end

    test "filters roles by search term (description)", %{roles: [role1 | _]} do
      result = Roles.list_roles(search: "Full system")

      assert length(result.roles) == 1
      assert hd(result.roles).id == role1.id
    end

    test "search is case-insensitive" do
      result = Roles.list_roles(search: "ADMINISTRATOR")

      assert length(result.roles) >= 1
      assert Enum.any?(result.roles, &(&1.name == "Administrator"))
    end

    test "sorts roles by id ascending", %{roles: [_role1, _role2 | _]} do
      result = Roles.list_roles(sort_by: :id, sort_order: :asc)

      role_ids = Enum.map(result.roles, & &1.id)
      assert role_ids == Enum.sort(role_ids)
    end

    test "sorts roles by id descending", %{roles: [_role1, _role2 | _]} do
      result = Roles.list_roles(sort_by: :id, sort_order: :desc)

      role_ids = Enum.map(result.roles, & &1.id)
      assert role_ids == Enum.sort(role_ids, :desc)
    end

    test "sorts roles by name ascending by default" do
      result = Roles.list_roles()

      names = Enum.map(result.roles, & &1.name)
      assert names == Enum.sort(names)
    end

    test "sorts roles by name descending" do
      result = Roles.list_roles(sort_by: :name, sort_order: :desc)

      names = Enum.map(result.roles, & &1.name)
      assert names == Enum.sort(names, :desc)
    end

    test "sorts roles by description ascending" do
      result = Roles.list_roles(sort_by: :description, sort_order: :asc)

      descriptions = Enum.map(result.roles, & &1.description)
      assert descriptions == Enum.sort(descriptions)
    end

    test "sorts roles by inserted_at ascending" do
      result = Roles.list_roles(sort_by: :inserted_at, sort_order: :asc)

      inserted_ats = Enum.map(result.roles, & &1.inserted_at)

      assert inserted_ats ==
               Enum.sort(inserted_ats, fn a, b ->
                 DateTime.compare(a, b) in [:lt, :eq]
               end)
    end

    test "combines search and sorting" do
      AccountsFixtures.role_fixture(%{name: "Test Role 1", description: "Test description 1"})
      AccountsFixtures.role_fixture(%{name: "Test Role 2", description: "Test description 2"})

      result = Roles.list_roles(search: "Test", sort_by: :name, sort_order: :asc)

      assert length(result.roles) >= 2
      names = Enum.map(result.roles, & &1.name)
      filtered_names = Enum.filter(names, &String.contains?(&1, "Test"))
      assert filtered_names == Enum.sort(filtered_names)
    end

    test "handles empty search term" do
      result1 = Roles.list_roles(search: "")
      result2 = Roles.list_roles(search: nil)

      # Both should return all roles
      assert result1.total == result2.total
    end

    test "handles page less than 1" do
      result = Roles.list_roles(page: 0)

      # Should default to page 1
      assert result.page == 1
    end

    test "handles invalid sort_by field" do
      result = Roles.list_roles(sort_by: :invalid_field)

      # Should still return results with default sorting
      assert result.total >= 3
    end

    test "handles invalid sort_order" do
      result = Roles.list_roles(sort_order: :invalid)

      # Should still return results
      assert result.total >= 3
    end

    test "preloads permissions association" do
      result = Roles.list_roles()

      role_with_permissions = Enum.find(result.roles, &(&1.permissions != []))

      assert role_with_permissions.permissions != []
      assert %Fortymm.Accounts.Permission{} = hd(role_with_permissions.permissions)
    end

    test "includes user_count for each role" do
      role = AccountsFixtures.role_fixture(%{name: "CountTest"})

      # Create users with this role
      user1 = AccountsFixtures.user_fixture()
      user2 = AccountsFixtures.user_fixture()
      {:ok, _} = Fortymm.Accounts.assign_role(user1, role.name)
      {:ok, _} = Fortymm.Accounts.assign_role(user2, role.name)

      result = Roles.list_roles(search: "CountTest")

      assert length(result.roles) == 1
      role_result = hd(result.roles)
      assert Map.has_key?(role_result, :user_count)
      assert role_result.user_count == 2
    end

    test "user_count is 0 for roles without users" do
      _role = AccountsFixtures.role_fixture(%{name: "EmptyRole"})

      result = Roles.list_roles(search: "EmptyRole")

      assert length(result.roles) == 1
      role_result = hd(result.roles)
      assert role_result.user_count == 0
    end

    test "calculates total_pages correctly" do
      # Create exactly 25 roles
      for i <- 1..25 do
        AccountsFixtures.role_fixture(%{
          name: "paging_role#{i}",
          description: "Paging description #{i}"
        })
      end

      result = Roles.list_roles(per_page: 10)
      total = result.total

      expected_pages = ceil(total / 10)
      assert result.total_pages == expected_pages
    end

    test "returns correct offset for pagination" do
      # Create 30 roles
      for i <- 1..30 do
        AccountsFixtures.role_fixture(%{
          name: "offset_role#{i}",
          description: "Offset description #{i}"
        })
      end

      page1 = Roles.list_roles(page: 1, per_page: 10, sort_by: :id, sort_order: :asc)
      page2 = Roles.list_roles(page: 2, per_page: 10, sort_by: :id, sort_order: :asc)

      # Ensure page 2 roles are different from page 1
      page1_ids = Enum.map(page1.roles, & &1.id)
      page2_ids = Enum.map(page2.roles, & &1.id)

      assert MapSet.disjoint?(MapSet.new(page1_ids), MapSet.new(page2_ids))
    end
  end

  describe "get_role/1" do
    test "returns role with preloaded permissions" do
      permission =
        AccountsFixtures.permission_fixture(%{
          name: "Test Permission",
          slug: "test_permission_get"
        })

      role = AccountsFixtures.role_fixture(%{name: "test_role"})
      role = Fortymm.Repo.preload(role, :permissions)

      {:ok, role} =
        role
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, [permission])
        |> Fortymm.Repo.update()

      result = Roles.get_role(role.id)

      assert result.id == role.id
      assert length(result.permissions) == 1
      assert hd(result.permissions).id == permission.id
    end

    test "returns nil for non-existent role" do
      result = Roles.get_role(999_999_999)

      assert result == nil
    end

    test "returns role without permissions" do
      role = AccountsFixtures.role_fixture(%{name: "no_perms_role"})

      result = Roles.get_role(role.id)

      assert result.id == role.id
      assert result.permissions == []
    end
  end

  describe "get_role!/1" do
    test "returns role with preloaded permissions" do
      permission =
        AccountsFixtures.permission_fixture(%{
          name: "Test Perm Get Bang",
          slug: "test_perm_get_bang"
        })

      role = AccountsFixtures.role_fixture(%{name: "test_role_2"})
      role = Fortymm.Repo.preload(role, :permissions)

      {:ok, role} =
        role
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:permissions, [permission])
        |> Fortymm.Repo.update()

      result = Roles.get_role!(role.id)

      assert result.id == role.id
      assert length(result.permissions) == 1
      assert hd(result.permissions).id == permission.id
    end

    test "raises for non-existent role" do
      assert_raise Ecto.NoResultsError, fn ->
        Roles.get_role!(999_999_999)
      end
    end
  end
end
