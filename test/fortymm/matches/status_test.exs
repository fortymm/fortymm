defmodule Fortymm.Matches.StatusTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.{Challenge, Status}

  describe "for_challenge/1" do
    test "returns :challenge_pending for pending challenges" do
      challenge = %Challenge{
        id: "test123",
        length_in_games: 3,
        rated: false,
        created_by_id: 1,
        status: "pending"
      }

      assert Status.for_challenge(challenge) == :challenge_pending
    end

    test "returns :challenge_accepted for accepted challenges" do
      challenge = %Challenge{
        id: "test456",
        length_in_games: 5,
        rated: true,
        created_by_id: 2,
        status: "accepted"
      }

      assert Status.for_challenge(challenge) == :challenge_accepted
    end

    test "returns :challenge_rejected for rejected challenges" do
      challenge = %Challenge{
        id: "test789",
        length_in_games: 7,
        rated: false,
        created_by_id: 3,
        status: "rejected"
      }

      assert Status.for_challenge(challenge) == :challenge_rejected
    end

    test "returns :challenge_cancelled for cancelled challenges" do
      challenge = %Challenge{
        id: "test101",
        length_in_games: 1,
        rated: true,
        created_by_id: 4,
        status: "cancelled"
      }

      assert Status.for_challenge(challenge) == :challenge_cancelled
    end

    test "status determination is independent of other challenge fields" do
      # Testing with different combinations of fields
      challenges = [
        %Challenge{id: "1", length_in_games: 1, rated: true, created_by_id: 1, status: "pending"},
        %Challenge{
          id: "2",
          length_in_games: 3,
          rated: false,
          created_by_id: 2,
          status: "accepted"
        },
        %Challenge{
          id: "3",
          length_in_games: 5,
          rated: true,
          created_by_id: 3,
          status: "rejected"
        },
        %Challenge{
          id: "4",
          length_in_games: 7,
          rated: false,
          created_by_id: 4,
          status: "cancelled"
        }
      ]

      assert Status.for_challenge(Enum.at(challenges, 0)) == :challenge_pending
      assert Status.for_challenge(Enum.at(challenges, 1)) == :challenge_accepted
      assert Status.for_challenge(Enum.at(challenges, 2)) == :challenge_rejected
      assert Status.for_challenge(Enum.at(challenges, 3)) == :challenge_cancelled
    end

    test "handles challenges with minimum valid values" do
      challenge = %Challenge{
        id: "min",
        length_in_games: 1,
        rated: false,
        created_by_id: 1,
        status: "pending"
      }

      assert Status.for_challenge(challenge) == :challenge_pending
    end

    test "handles challenges with maximum valid length_in_games" do
      challenge = %Challenge{
        id: "max",
        length_in_games: 7,
        rated: true,
        created_by_id: 999_999,
        status: "accepted"
      }

      assert Status.for_challenge(challenge) == :challenge_accepted
    end
  end
end
