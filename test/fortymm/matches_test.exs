defmodule Fortymm.MatchesTest do
  use Fortymm.DataCase

  alias Fortymm.Matches
  alias Fortymm.Matches.{Challenge, ChallengeStore}

  setup do
    # Clear ETS table before each test
    ChallengeStore.clear()
    :ok
  end

  describe "challenge_changeset/1" do
    test "valid with length_in_games of 1" do
      changeset = Matches.challenge_changeset(%{length_in_games: 1, created_by_id: 1})
      assert changeset.valid?
    end

    test "valid with length_in_games of 3" do
      changeset = Matches.challenge_changeset(%{length_in_games: 3, created_by_id: 1})
      assert changeset.valid?
    end

    test "valid with length_in_games of 5" do
      changeset = Matches.challenge_changeset(%{length_in_games: 5, created_by_id: 1})
      assert changeset.valid?
    end

    test "valid with length_in_games of 7" do
      changeset = Matches.challenge_changeset(%{length_in_games: 7, created_by_id: 1})
      assert changeset.valid?
    end

    test "invalid with length_in_games of 2" do
      changeset = Matches.challenge_changeset(%{length_in_games: 2})
      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "invalid with length_in_games of 4" do
      changeset = Matches.challenge_changeset(%{length_in_games: 4})
      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "invalid with length_in_games of 6" do
      changeset = Matches.challenge_changeset(%{length_in_games: 6})
      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "invalid with length_in_games of 0" do
      changeset = Matches.challenge_changeset(%{length_in_games: 0})
      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "invalid with length_in_games of 10" do
      changeset = Matches.challenge_changeset(%{length_in_games: 10})
      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "invalid without length_in_games" do
      changeset = Matches.challenge_changeset(%{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).length_in_games
    end

    test "invalid with nil length_in_games" do
      changeset = Matches.challenge_changeset(%{length_in_games: nil})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).length_in_games
    end

    test "invalid without created_by_id" do
      changeset = Matches.challenge_changeset(%{length_in_games: 3})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "invalid with nil created_by_id" do
      changeset = Matches.challenge_changeset(%{length_in_games: 3, created_by_id: nil})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "valid with created_by_id" do
      changeset = Matches.challenge_changeset(%{length_in_games: 3, created_by_id: 1})
      assert changeset.valid?
    end
  end

  describe "Challenge.changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 3, rated: true, created_by_id: 1})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :length_in_games) == 3
      assert Ecto.Changeset.get_field(changeset, :rated) == true
    end

    test "returns an invalid changeset with incorrect length" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 8, rated: false, created_by_id: 1})

      refute changeset.valid?
    end

    test "defaults rated to false when not provided" do
      changeset = Challenge.changeset(%Challenge{}, %{length_in_games: 3, created_by_id: 1})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == false
    end

    test "can explicitly set rated to false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 3, rated: false, created_by_id: 1})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == false
    end

    test "accepts rated as true" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 5, rated: true, created_by_id: 1})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == true
    end

    test "accepts rated as false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 5, rated: false, created_by_id: 1})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == false
    end

    test "requires created_by_id" do
      changeset = Challenge.changeset(%Challenge{}, %{length_in_games: 3, rated: false})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id correctly" do
      changeset =
        Challenge.changeset(%Challenge{}, %{length_in_games: 3, rated: false, created_by_id: 42})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :created_by_id) == 42
    end
  end

  describe "create_challenge/1" do
    test "creates and stores a valid challenge in ETS" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: 1})

      assert challenge.length_in_games == 3
      assert challenge.rated == false
      assert challenge.created_by_id == 1
      assert is_binary(challenge.id)
      assert String.length(challenge.id) == 32
    end

    test "creates a rated challenge" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: 1})

      assert challenge.length_in_games == 5
      assert challenge.rated == true
      assert challenge.created_by_id == 1
    end

    test "returns error for invalid challenge" do
      assert {:error, changeset} =
               Matches.create_challenge(%{length_in_games: 2, rated: false, created_by_id: 1})

      refute changeset.valid?
      assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
    end

    test "defaults rated to false when not provided" do
      assert {:ok, challenge} = Matches.create_challenge(%{length_in_games: 3, created_by_id: 1})
      assert challenge.length_in_games == 3
      assert challenge.rated == false
    end

    test "generates unique IDs for each challenge" do
      {:ok, challenge1} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: 1})

      {:ok, challenge2} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: 1})

      assert challenge1.id != challenge2.id
    end

    test "stores challenge so it can be retrieved" do
      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 7, rated: true, created_by_id: 1})

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.length_in_games == 7
      assert retrieved.rated == true
      assert retrieved.created_by_id == 1
    end

    test "requires created_by_id" do
      assert {:error, changeset} = Matches.create_challenge(%{length_in_games: 3, rated: false})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id from different users" do
      {:ok, challenge1} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: 1})

      {:ok, challenge2} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: 2})

      assert challenge1.created_by_id == 1
      assert challenge2.created_by_id == 2
    end
  end

  describe "get_challenge/1" do
    test "returns challenge when it exists" do
      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: false, created_by_id: 1})

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.length_in_games == 5
      assert retrieved.rated == false
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Matches.get_challenge("nonexistent-id")
    end
  end

  describe "list_challenges/0" do
    test "returns empty list when no challenges exist" do
      assert Matches.list_challenges() == []
    end

    test "returns all challenges" do
      {:ok, challenge1} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: 1})

      {:ok, challenge2} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: 1})

      {:ok, challenge3} =
        Matches.create_challenge(%{length_in_games: 7, rated: false, created_by_id: 1})

      challenges = Matches.list_challenges()
      assert length(challenges) == 3
      assert challenge1 in challenges
      assert challenge2 in challenges
      assert challenge3 in challenges
    end
  end

  describe "delete_challenge/1" do
    test "deletes an existing challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: 1})

      assert :ok = Matches.delete_challenge(challenge.id)
      assert {:error, :not_found} = Matches.get_challenge(challenge.id)
    end

    test "returns ok even when challenge does not exist" do
      assert :ok = Matches.delete_challenge("nonexistent-id")
    end
  end
end
