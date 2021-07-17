defmodule Fortymm.LeagueDataIngestionsTest do
  use Fortymm.DataCase

  alias Fortymm.LeagueDataIngestions
  alias Fortymm.Factory

  describe "league_data_ingestions" do
    alias Fortymm.LeagueDataIngestions.LeagueDataIngestion

    @invalid_attrs %{completed_at: nil, started_at: nil, status: nil}

    def league_data_ingestion_fixture(attrs \\ %{}) do
      Factory.insert(:league_data_ingestion, attrs)
    end

    test "list_league_data_ingestions/0 returns all league_data_ingestions" do
      league_data_ingestion = league_data_ingestion_fixture()
      assert LeagueDataIngestions.list_league_data_ingestions() == [league_data_ingestion]
    end

    test "get_league_data_ingestion!/1 returns the league_data_ingestion with given id" do
      league_data_ingestion = league_data_ingestion_fixture()

      assert LeagueDataIngestions.get_league_data_ingestion!(league_data_ingestion.id) ==
               league_data_ingestion
    end

    test "create_league_data_ingestion/1 with valid data creates a league_data_ingestion" do
      valid_attrs = Factory.params_for(:league_data_ingestion)

      assert {:ok, %LeagueDataIngestion{} = league_data_ingestion} =
               LeagueDataIngestions.create_league_data_ingestion(valid_attrs)

      assert league_data_ingestion.completed_at == valid_attrs.completed_at
      assert league_data_ingestion.started_at == valid_attrs.started_at
      assert league_data_ingestion.status == valid_attrs.status
    end

    test "create_league_data_ingestion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               LeagueDataIngestions.create_league_data_ingestion(@invalid_attrs)
    end

    test "update_league_data_ingestion/2 with valid data updates the league_data_ingestion" do
      update_attrs =
        Factory.params_for(:league_data_ingestion, status: LeagueDataIngestion.completed())

      league_data_ingestion = league_data_ingestion_fixture()

      assert {:ok, %LeagueDataIngestion{} = league_data_ingestion} =
               LeagueDataIngestions.update_league_data_ingestion(
                 league_data_ingestion,
                 update_attrs
               )

      assert league_data_ingestion.completed_at == update_attrs.completed_at
      assert league_data_ingestion.started_at == update_attrs.started_at
      assert league_data_ingestion.status == update_attrs.status
    end

    test "update_league_data_ingestion/2 with invalid data returns error changeset" do
      league_data_ingestion = league_data_ingestion_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LeagueDataIngestions.update_league_data_ingestion(
                 league_data_ingestion,
                 @invalid_attrs
               )

      assert league_data_ingestion ==
               LeagueDataIngestions.get_league_data_ingestion!(league_data_ingestion.id)
    end

    test "delete_league_data_ingestion/1 deletes the league_data_ingestion" do
      league_data_ingestion = league_data_ingestion_fixture()

      assert {:ok, %LeagueDataIngestion{}} =
               LeagueDataIngestions.delete_league_data_ingestion(league_data_ingestion)

      assert_raise Ecto.NoResultsError, fn ->
        LeagueDataIngestions.get_league_data_ingestion!(league_data_ingestion.id)
      end
    end

    test "change_league_data_ingestion/1 returns a league_data_ingestion changeset" do
      league_data_ingestion = league_data_ingestion_fixture()

      assert %Ecto.Changeset{} =
               LeagueDataIngestions.change_league_data_ingestion(league_data_ingestion)
    end
  end
end
