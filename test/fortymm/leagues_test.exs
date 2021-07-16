defmodule Fortymm.LeaguesTest do
  use Fortymm.DataCase

  alias Fortymm.Leagues
  alias Fortymm.Factory

  describe "leagues" do
    alias Fortymm.Leagues.League

    @invalid_attrs %{name: nil}

    def league_fixture(attrs \\ %{}) do
      Factory.insert(:league, attrs)
    end

    test "list_leagues/0 returns all leagues" do
      league = league_fixture()
      assert Leagues.list_leagues() == [league]
    end

    test "get_league!/1 returns the league with given id" do
      league = league_fixture()
      assert Leagues.get_league!(league.id) == league
    end

    test "get_league_by_slug!/1 returns the league with given slug" do
      league = league_fixture()
      assert Leagues.get_league_by_slug!(league.slug) == league
    end

    test "create_league/1 with valid data creates a league" do
      valid_attrs = Factory.params_for(:league)
      assert {:ok, %League{} = league} = Leagues.create_league(valid_attrs)
      assert league.name == valid_attrs.name
    end

    test "create_league/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Leagues.create_league(@invalid_attrs)
    end

    test "update_league/2 with valid data updates the league" do
      league = league_fixture()
      update_attrs = Factory.params_for(:league)
      assert {:ok, %League{} = league} = Leagues.update_league(league, update_attrs)
      assert league.name == update_attrs.name
    end

    test "update_league/2 with invalid data returns error changeset" do
      league = league_fixture()
      assert {:error, %Ecto.Changeset{}} = Leagues.update_league(league, @invalid_attrs)
      assert league == Leagues.get_league!(league.id)
    end

    test "delete_league/1 deletes the league" do
      league = league_fixture()
      assert {:ok, %League{}} = Leagues.delete_league(league)
      assert_raise Ecto.NoResultsError, fn -> Leagues.get_league!(league.id) end
    end

    test "change_league/1 returns a league changeset" do
      league = league_fixture()
      assert %Ecto.Changeset{} = Leagues.change_league(league)
    end
  end
end
