defmodule Fortymm.Matches.MatchStoreTest do
  use ExUnit.Case, async: false

  alias Fortymm.Matches.{Match, MatchStore}

  setup do
    # Clear ETS table before each test
    MatchStore.clear()
    :ok
  end

  describe "insert/2 and get/1" do
    test "inserts and retrieves a match" do
      match = %Match{
        id: "test-match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      assert :ok = MatchStore.insert("test-match-1", match)
      assert {:ok, retrieved} = MatchStore.get("test-match-1")
      assert retrieved.id == "test-match-1"
      assert retrieved.status == "pending"
    end

    test "returns error when match does not exist" do
      assert {:error, :not_found} = MatchStore.get("nonexistent-id")
    end

    test "overwrites existing match with same ID" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-1",
        status: "in_progress",
        match_configuration: %{length_in_games: 5, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-1", match2)

      {:ok, retrieved} = MatchStore.get("match-1")
      assert retrieved.status == "in_progress"
      assert retrieved.match_configuration.length_in_games == 5
      assert retrieved.match_configuration.rated == true
    end

    test "stores multiple matches independently" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 1, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 7, rated: true}
      }

      match3 = %Match{
        id: "match-3",
        status: "complete",
        match_configuration: %{length_in_games: 5, rated: false}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-2", match2)
      MatchStore.insert("match-3", match3)

      {:ok, retrieved1} = MatchStore.get("match-1")
      {:ok, retrieved2} = MatchStore.get("match-2")
      {:ok, retrieved3} = MatchStore.get("match-3")

      assert retrieved1.id == "match-1"
      assert retrieved1.status == "pending"
      assert retrieved2.id == "match-2"
      assert retrieved2.status == "in_progress"
      assert retrieved3.id == "match-3"
      assert retrieved3.status == "complete"
    end

    test "stores matches with different statuses" do
      statuses = ["pending", "in_progress", "canceled", "aborted", "complete"]

      for {status, index} <- Enum.with_index(statuses) do
        id = "match-#{index}"

        match = %Match{
          id: id,
          status: status,
          match_configuration: %{length_in_games: 3, rated: false}
        }

        MatchStore.insert(id, match)
        {:ok, retrieved} = MatchStore.get(id)
        assert retrieved.status == status
      end
    end

    test "stores matches with different configurations" do
      configs = [
        %{length_in_games: 1, rated: false},
        %{length_in_games: 3, rated: true},
        %{length_in_games: 5, rated: false},
        %{length_in_games: 7, rated: true}
      ]

      for {config, index} <- Enum.with_index(configs) do
        id = "match-#{index}"

        match = %Match{
          id: id,
          status: "pending",
          match_configuration: config
        }

        MatchStore.insert(id, match)
        {:ok, retrieved} = MatchStore.get(id)
        assert retrieved.match_configuration.length_in_games == config.length_in_games
        assert retrieved.match_configuration.rated == config.rated
      end
    end
  end

  describe "delete/1" do
    test "deletes an existing match" do
      match = %Match{
        id: "match-to-delete",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      MatchStore.insert("match-to-delete", match)
      assert {:ok, _} = MatchStore.get("match-to-delete")

      assert :ok = MatchStore.delete("match-to-delete")
      assert {:error, :not_found} = MatchStore.get("match-to-delete")
    end

    test "returns ok even when match does not exist" do
      assert :ok = MatchStore.delete("nonexistent-id")
    end

    test "deletes only the specified match" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 5, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-2", match2)

      MatchStore.delete("match-1")

      assert {:error, :not_found} = MatchStore.get("match-1")
      assert {:ok, retrieved} = MatchStore.get("match-2")
      assert retrieved.id == "match-2"
    end

    test "can delete and re-insert with same ID" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-1",
        status: "complete",
        match_configuration: %{length_in_games: 7, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.delete("match-1")
      MatchStore.insert("match-1", match2)

      {:ok, retrieved} = MatchStore.get("match-1")
      assert retrieved.status == "complete"
      assert retrieved.match_configuration.length_in_games == 7
    end
  end

  describe "list_all/0" do
    test "returns empty list when no matches exist" do
      assert MatchStore.list_all() == []
    end

    test "returns all stored matches" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 1, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 3, rated: true}
      }

      match3 = %Match{
        id: "match-3",
        status: "complete",
        match_configuration: %{length_in_games: 7, rated: false}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-2", match2)
      MatchStore.insert("match-3", match3)

      matches = MatchStore.list_all()
      assert length(matches) == 3
      assert match1 in matches
      assert match2 in matches
      assert match3 in matches
    end

    test "returns updated list after insertion" do
      assert MatchStore.list_all() == []

      match = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      MatchStore.insert("match-1", match)

      matches = MatchStore.list_all()
      assert length(matches) == 1
      assert match in matches
    end

    test "returns updated list after deletion" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 5, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-2", match2)

      assert length(MatchStore.list_all()) == 2

      MatchStore.delete("match-1")

      matches = MatchStore.list_all()
      assert length(matches) == 1
      assert match2 in matches
      refute match1 in matches
    end

    test "handles large number of matches" do
      for i <- 1..100 do
        match = %Match{
          id: "match-#{i}",
          status: "pending",
          match_configuration: %{length_in_games: 3, rated: false}
        }

        MatchStore.insert("match-#{i}", match)
      end

      matches = MatchStore.list_all()
      assert length(matches) == 100
    end
  end

  describe "clear/0" do
    test "clears all matches from the store" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 5, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.insert("match-2", match2)

      assert length(MatchStore.list_all()) == 2

      assert :ok = MatchStore.clear()

      assert MatchStore.list_all() == []
      assert {:error, :not_found} = MatchStore.get("match-1")
      assert {:error, :not_found} = MatchStore.get("match-2")
    end

    test "can insert matches after clearing" do
      match1 = %Match{
        id: "match-1",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        match_configuration: %{length_in_games: 5, rated: true}
      }

      MatchStore.insert("match-1", match1)
      MatchStore.clear()
      MatchStore.insert("match-2", match2)

      matches = MatchStore.list_all()
      assert length(matches) == 1
      assert match2 in matches
    end

    test "returns ok when clearing empty store" do
      assert :ok = MatchStore.clear()
      assert MatchStore.list_all() == []
    end
  end

  describe "concurrent operations" do
    test "handles concurrent inserts" do
      tasks =
        for i <- 1..50 do
          Task.async(fn ->
            match = %Match{
              id: "match-#{i}",
              status: "pending",
              match_configuration: %{length_in_games: 3, rated: false}
            }

            MatchStore.insert("match-#{i}", match)
          end)
        end

      Task.await_many(tasks)

      matches = MatchStore.list_all()
      assert length(matches) == 50
    end

    test "handles concurrent reads" do
      match = %Match{
        id: "shared-match",
        status: "pending",
        match_configuration: %{length_in_games: 3, rated: false}
      }

      MatchStore.insert("shared-match", match)

      tasks =
        for _i <- 1..100 do
          Task.async(fn ->
            MatchStore.get("shared-match")
          end)
        end

      results = Task.await_many(tasks)

      assert Enum.all?(results, fn result ->
               result == {:ok, match}
             end)
    end
  end

  describe "edge cases" do
    test "handles match with all valid statuses" do
      statuses = ["pending", "in_progress", "canceled", "aborted", "complete"]

      for status <- statuses do
        match = %Match{
          id: "match-#{status}",
          status: status,
          match_configuration: %{length_in_games: 5, rated: true}
        }

        MatchStore.insert("match-#{status}", match)
        {:ok, retrieved} = MatchStore.get("match-#{status}")
        assert retrieved.status == status
      end
    end

    test "handles match with all valid configuration lengths" do
      lengths = [1, 3, 5, 7]

      for length <- lengths do
        match = %Match{
          id: "match-length-#{length}",
          status: "pending",
          match_configuration: %{length_in_games: length, rated: false}
        }

        MatchStore.insert("match-length-#{length}", match)
        {:ok, retrieved} = MatchStore.get("match-length-#{length}")
        assert retrieved.match_configuration.length_in_games == length
      end
    end

    test "handles match IDs with special characters" do
      special_ids = [
        "match-with-dashes",
        "match_with_underscores",
        "match.with.dots",
        "match:with:colons"
      ]

      for id <- special_ids do
        match = %Match{
          id: id,
          status: "pending",
          match_configuration: %{length_in_games: 3, rated: false}
        }

        MatchStore.insert(id, match)
        {:ok, retrieved} = MatchStore.get(id)
        assert retrieved.id == id
      end
    end
  end
end
