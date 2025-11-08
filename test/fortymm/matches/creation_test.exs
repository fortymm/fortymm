defmodule Fortymm.Matches.CreationTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.{Challenge, Configuration, Creation, Match, MatchStore}

  setup do
    # Clear the match store before each test
    MatchStore.clear()
    :ok
  end

  describe "from_challenge/2" do
    test "creates a valid match from a challenge" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 2)
      assert %Match{} = match
      assert match.status == "pending"
      assert match.match_configuration.length_in_games == 3
      assert match.match_configuration.rated == false
      assert length(match.participants) == 2
    end

    test "creates participants with correct user IDs" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 42,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 5,
          rated: true
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 99)

      participants = match.participants
      assert length(participants) == 2

      participant_1 = Enum.find(participants, &(&1.participant_number == 1))
      participant_2 = Enum.find(participants, &(&1.participant_number == 2))

      assert participant_1.user_id == 42
      assert participant_2.user_id == 99
    end

    test "assigns participant numbers correctly" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 2)

      participant_numbers = Enum.map(match.participants, & &1.participant_number)
      assert 1 in participant_numbers
      assert 2 in participant_numbers
    end

    test "stores match in MatchStore" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 2)
      assert {:ok, stored_match} = MatchStore.get(match.id)
      assert stored_match.id == match.id
      assert stored_match.status == "pending"
    end

    test "generates unique match ID" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match1} = Creation.from_challenge(challenge, 2)
      assert {:ok, match2} = Creation.from_challenge(challenge, 3)

      assert match1.id != match2.id
      assert is_binary(match1.id)
      assert is_binary(match2.id)
    end

    test "copies configuration from challenge" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 7,
          rated: true
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 2)
      assert match.match_configuration.length_in_games == 7
      assert match.match_configuration.rated == true
    end

    test "returns error when acceptor is same as creator" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:error, changeset} = Creation.from_challenge(challenge, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :acceptor_id)
      assert "cannot accept your own challenge" in errors.acceptor_id
    end

    test "returns error when challenge is not pending" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "accepted",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:error, changeset} = Creation.from_challenge(challenge, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :challenge)
      assert "must be pending, but is accepted" in errors.challenge
    end

    test "returns error when challenge is rejected" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "rejected",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:error, changeset} = Creation.from_challenge(challenge, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is rejected" in errors.challenge
    end

    test "returns error when challenge is cancelled" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "cancelled",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:error, changeset} = Creation.from_challenge(challenge, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is cancelled" in errors.challenge
    end

    test "handles different configuration lengths" do
      for length <- [1, 3, 5, 7] do
        challenge = %Challenge{
          id: "test-challenge-#{length}",
          created_by_id: 1,
          status: "pending",
          configuration: %Configuration{
            id: nil,
            length_in_games: length,
            rated: false
          }
        }

        assert {:ok, match} = Creation.from_challenge(challenge, 2)
        assert match.match_configuration.length_in_games == length
      end
    end

    test "handles rated and unrated configurations" do
      # Rated challenge
      rated_challenge = %Challenge{
        id: "rated-challenge",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: true
        }
      }

      assert {:ok, rated_match} = Creation.from_challenge(rated_challenge, 2)
      assert rated_match.match_configuration.rated == true

      # Unrated challenge
      unrated_challenge = %Challenge{
        id: "unrated-challenge",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, unrated_match} = Creation.from_challenge(unrated_challenge, 2)
      assert unrated_match.match_configuration.rated == false
    end

    test "handles large user IDs" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 999_999_999,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 888_888_888)

      participant_1 = Enum.find(match.participants, &(&1.participant_number == 1))
      participant_2 = Enum.find(match.participants, &(&1.participant_number == 2))

      assert participant_1.user_id == 999_999_999
      assert participant_2.user_id == 888_888_888
    end

    test "creates match with pending status regardless of challenge status" do
      # The function validates pending, but let's ensure the created match is always pending
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      assert {:ok, match} = Creation.from_challenge(challenge, 2)
      assert match.status == "pending"
    end

    test "does not store match when validation fails" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      # This should fail because acceptor is same as creator
      assert {:error, _changeset} = Creation.from_challenge(challenge, 1)

      # Verify no matches were stored
      assert MatchStore.list_all() == []
    end

    test "creates multiple matches from same challenge with different acceptors" do
      challenge = %Challenge{
        id: "test-challenge-id",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{
          id: nil,
          length_in_games: 3,
          rated: false
        }
      }

      # Create first match
      assert {:ok, match1} = Creation.from_challenge(challenge, 2)

      # Create second match (simulating challenge being reused)
      assert {:ok, match2} = Creation.from_challenge(challenge, 3)

      # Both matches should exist and be different
      assert match1.id != match2.id
      assert {:ok, _} = MatchStore.get(match1.id)
      assert {:ok, _} = MatchStore.get(match2.id)

      # Verify participants are correct
      match1_participant_2 = Enum.find(match1.participants, &(&1.participant_number == 2))
      match2_participant_2 = Enum.find(match2.participants, &(&1.participant_number == 2))

      assert match1_participant_2.user_id == 2
      assert match2_participant_2.user_id == 3
    end
  end
end
