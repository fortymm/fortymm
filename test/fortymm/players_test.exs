defmodule Fortymm.PlayersTest do
  use Fortymm.DataCase

  alias Fortymm.Players
  alias Fortymm.Factory

  describe "players" do
    alias Fortymm.Players.Player

    @invalid_attrs %{first_name: nil, last_name: nil}

    def player_fixture(attrs \\ %{}) do
      Factory.insert(:player, attrs)
    end

    test "list_players/0 returns all players" do
      player = player_fixture()
      assert Players.list_players() == [player]
    end

    test "get_player!/1 returns the player with given id" do
      player = player_fixture()
      assert Players.get_player!(player.id) == player
    end

    test "create_player/1 with valid data creates a player" do
      valid_attrs = Factory.params_for(:player)
      assert {:ok, %Player{} = player} = Players.create_player(valid_attrs)
      assert player.first_name == valid_attrs.first_name
      assert player.last_name == valid_attrs.last_name
    end

    test "create_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Players.create_player(@invalid_attrs)
    end

    test "update_player/2 with valid data updates the player" do
      player = player_fixture()
      update_attrs = Factory.params_for(:player)
      assert {:ok, %Player{} = player} = Players.update_player(player, update_attrs)
      assert player.first_name == update_attrs.first_name
      assert player.last_name == update_attrs.last_name
    end

    test "update_player/2 with invalid data returns error changeset" do
      player = player_fixture()
      assert {:error, %Ecto.Changeset{}} = Players.update_player(player, @invalid_attrs)
      assert player == Players.get_player!(player.id)
    end

    test "delete_player/1 deletes the player" do
      player = player_fixture()
      assert {:ok, %Player{}} = Players.delete_player(player)
      assert_raise Ecto.NoResultsError, fn -> Players.get_player!(player.id) end
    end

    test "change_player/1 returns a player changeset" do
      player = player_fixture()
      assert %Ecto.Changeset{} = Players.change_player(player)
    end
  end
end
