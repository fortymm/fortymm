defmodule Fortymm.LeagueMembershipsTest do
  use Fortymm.DataCase

  alias Fortymm.LeagueMemberships
  alias Fortymm.Factory

  describe "league_memberships" do
    alias Fortymm.LeagueMemberships.LeagueMembership

    @invalid_attrs %{external_league_ref: nil, player_id: nil, league_id: nil}

    def league_membership_fixture(attrs \\ %{}) do
      league_membership_attrs =
        :league_membership
        |> Factory.params_for(attrs)
        |> Factory.with_league()
        |> Factory.with_player()

      Factory.insert(:league_membership, league_membership_attrs)
    end

    test "list_league_memberships/0 returns all league_memberships" do
      league_membership = league_membership_fixture()
      assert LeagueMemberships.list_league_memberships() == [league_membership]
    end

    test "get_league_membership!/1 returns the league_membership with given id" do
      league_membership = league_membership_fixture()
      assert LeagueMemberships.get_league_membership!(league_membership.id) == league_membership
    end

    test "create_league_membership/1 with valid data creates a league_membership" do
      valid_attrs =
        :league_membership
        |> Factory.params_for()
        |> Factory.with_league()
        |> Factory.with_player()

      assert {:ok, %LeagueMembership{} = league_membership} =
               LeagueMemberships.create_league_membership(valid_attrs)

      assert league_membership.external_league_ref == valid_attrs.external_league_ref
      assert league_membership.player_id == valid_attrs.player_id
      assert league_membership.league_id == valid_attrs.league_id
    end

    test "create_league_membership/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               LeagueMemberships.create_league_membership(@invalid_attrs)
    end

    test "update_league_membership/2 with valid data updates the league_membership" do
      league_membership = league_membership_fixture()

      update_attrs =
        :league_membership
        |> Factory.params_for()
        |> Factory.with_league()
        |> Factory.with_player()

      assert {:ok, %LeagueMembership{} = league_membership} =
               LeagueMemberships.update_league_membership(league_membership, update_attrs)

      assert league_membership.external_league_ref == update_attrs.external_league_ref
      assert league_membership.player_id == update_attrs.player_id
      assert league_membership.league_id == update_attrs.league_id
    end

    test "update_league_membership/2 with invalid data returns error changeset" do
      league_membership = league_membership_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LeagueMemberships.update_league_membership(league_membership, @invalid_attrs)

      assert league_membership == LeagueMemberships.get_league_membership!(league_membership.id)
    end

    test "delete_league_membership/1 deletes the league_membership" do
      league_membership = league_membership_fixture()

      assert {:ok, %LeagueMembership{}} =
               LeagueMemberships.delete_league_membership(league_membership)

      assert_raise Ecto.NoResultsError, fn ->
        LeagueMemberships.get_league_membership!(league_membership.id)
      end
    end

    test "change_league_membership/1 returns a league_membership changeset" do
      league_membership = league_membership_fixture()
      assert %Ecto.Changeset{} = LeagueMemberships.change_league_membership(league_membership)
    end
  end
end
