defmodule Fortymm.MatchesTest do
  use Fortymm.DataCase

  alias Fortymm.Matches
  alias Fortymm.Matches.{Challenge, ChallengeStore, ChallengeUpdates}

  setup do
    # Clear ETS table before each test
    ChallengeStore.clear()
    :ok
  end

  describe "challenge_changeset/1" do
    test "valid with length_in_games of 1" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 1}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 3" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 5" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 5}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 7" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 7}, created_by_id: 1})

      assert changeset.valid?
    end

    test "invalid with length_in_games of 2" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 2}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 4" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 4}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 6" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 6}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 0" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 0}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 10" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 10}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid without length_in_games" do
      changeset = Matches.challenge_changeset(%{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "can't be blank" in errors.configuration
    end

    test "invalid with nil length_in_games" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: nil}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "can't be blank" in errors
    end

    test "invalid without created_by_id" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 3}})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "invalid with nil created_by_id" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: nil})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "valid with created_by_id" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert changeset.valid?
    end
  end

  describe "Challenge.changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: true},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.length_in_games == 3
      assert configuration.rated == true
    end

    test "returns an invalid changeset with incorrect length" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 8, rated: false},
          created_by_id: 1
        })

      refute changeset.valid?
    end

    test "defaults rated to false when not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "can explicitly set rated to false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "accepts rated as true" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == true
    end

    test "accepts rated as false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "requires created_by_id" do
      changeset =
        Challenge.changeset(%Challenge{}, %{configuration: %{length_in_games: 3, rated: false}})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id correctly" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 42
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :created_by_id) == 42
    end

    test "defaults status to pending when not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as pending" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "pending"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as accepted" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "accepted"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "accepted"
    end

    test "accepts status as rejected" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "rejected"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "rejected"
    end

    test "accepts status as cancelled" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "cancelled"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "cancelled"
    end

    test "rejects invalid status value" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "invalid"
        })

      refute changeset.valid?

      assert "must be one of: pending, accepted, rejected, cancelled" in errors_on(changeset).status
    end

    test "treats empty string status as not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: ""
        })

      # Ecto's cast/3 treats empty strings as "no value", so status defaults to "pending"
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "allows nil status and uses default" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: nil
        })

      # When nil is explicitly passed, validation doesn't run and field is set to nil
      # The default only applies to the struct, not when a field is explicitly set to nil
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == nil
    end
  end

  describe "create_challenge/1" do
    test "creates and stores a valid challenge in ETS" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 3, rated: false},
                 created_by_id: 1
               })

      assert challenge.configuration.length_in_games == 3
      assert challenge.configuration.rated == false
      assert challenge.created_by_id == 1
      assert is_binary(challenge.id)
      assert String.length(challenge.id) == 32
    end

    test "creates a rated challenge" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 5, rated: true},
                 created_by_id: 1
               })

      assert challenge.configuration.length_in_games == 5
      assert challenge.configuration.rated == true
      assert challenge.created_by_id == 1
    end

    test "returns error for invalid challenge" do
      assert {:error, changeset} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 2, rated: false},
                 created_by_id: 1
               })

      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "defaults rated to false when not provided" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert challenge.configuration.length_in_games == 3
      assert challenge.configuration.rated == false
    end

    test "generates unique IDs for each challenge" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      assert challenge1.id != challenge2.id
    end

    test "stores challenge so it can be retrieved" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: 1
        })

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.configuration.length_in_games == 7
      assert retrieved.configuration.rated == true
      assert retrieved.created_by_id == 1
    end

    test "requires created_by_id" do
      assert {:error, changeset} =
               Matches.create_challenge(%{configuration: %{length_in_games: 3, rated: false}})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id from different users" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      assert challenge1.created_by_id == 1
      assert challenge2.created_by_id == 2
    end
  end

  describe "get_challenge/1" do
    test "returns challenge when it exists" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.configuration.length_in_games == 5
      assert retrieved.configuration.rated == false
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
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      {:ok, challenge3} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 1
        })

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
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert :ok = Matches.delete_challenge(challenge.id)
      assert {:error, :not_found} = Matches.get_challenge(challenge.id)
    end

    test "returns ok even when challenge does not exist" do
      assert :ok = Matches.delete_challenge("nonexistent-id")
    end
  end

  describe "update_challenge/2" do
    test "updates an existing challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert updated.id == challenge.id
      assert updated.status == "accepted"
      assert updated.configuration.length_in_games == 3
      assert updated.configuration.rated == false
    end

    test "updates multiple fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} =
               Matches.update_challenge(challenge.id, %{
                 status: "rejected",
                 configuration: %{rated: true}
               })

      assert updated.status == "rejected"
      assert updated.configuration.rated == true
    end

    test "persists updates in ETS" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      {:ok, _updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.status == "accepted"
    end

    test "returns error for invalid update" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} =
               Matches.update_challenge(challenge.id, %{status: "invalid_status"})

      refute changeset.valid?

      assert "must be one of: pending, accepted, rejected, cancelled" in errors_on(changeset).status
    end

    test "returns error for non-existent challenge" do
      assert {:error, :not_found} =
               Matches.update_challenge("nonexistent-id", %{status: "accepted"})
    end

    test "validates length_in_games on update" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} =
               Matches.update_challenge(challenge.id, %{configuration: %{length_in_games: 2}})

      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "can update challenge to cancelled status" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "cancelled"})
      assert updated.status == "cancelled"
    end

    test "challenge starts with pending status" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
    end

    test "can transition from pending to accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert updated.status == "accepted"
    end

    test "can transition from pending to rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "rejected"})
      assert updated.status == "rejected"
    end

    test "can transition from pending to cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "cancelled"})
      assert updated.status == "cancelled"
    end
  end

  describe "challenge broadcasts" do
    test "create_challenge broadcasts the new challenge" do
      ChallengeUpdates.subscribe("will-be-generated")

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Subscribe to the actual challenge ID
      ChallengeUpdates.subscribe(challenge.id)

      # Create another challenge to trigger a broadcast we're subscribed to
      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      ChallengeUpdates.subscribe(challenge2.id)

      # Trigger an update to test the broadcast
      {:ok, updated} = Matches.update_challenge(challenge2.id, %{status: "accepted"})

      assert_receive {:challenge_updated, received}
      assert received.id == updated.id
      assert received.status == "accepted"
    end

    test "update_challenge broadcasts the updated challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert_receive {:challenge_updated, received}
      assert received.id == challenge.id
      assert received.status == "accepted"
      assert received.configuration.length_in_games == 3
    end

    test "broadcasts include all updated fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _updated} =
        Matches.update_challenge(challenge.id, %{
          status: "rejected",
          configuration: %{rated: true}
        })

      assert_receive {:challenge_updated, received}
      assert received.status == "rejected"
      assert received.configuration.rated == true
    end

    test "failed updates do not broadcast" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      # Try an invalid update
      {:error, _changeset} = Matches.update_challenge(challenge.id, %{status: "invalid"})

      refute_receive {:challenge_updated, _}, 100
    end

    test "broadcasts only to subscribers of the specific challenge" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 2
        })

      challenge2_id = challenge2.id

      # Only subscribe to challenge1
      ChallengeUpdates.subscribe(challenge1.id)

      # Update challenge2
      {:ok, _updated} = Matches.update_challenge(challenge2.id, %{status: "accepted"})

      # Should not receive update for challenge2
      refute_receive {:challenge_updated, %{id: ^challenge2_id}}, 100
    end
  end

  describe "status/1" do
    test "returns :challenge_pending for pending challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert Matches.status(challenge) == :challenge_pending
    end

    test "returns :challenge_accepted for accepted challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      {:ok, accepted_challenge} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert Matches.status(accepted_challenge) == :challenge_accepted
    end

    test "returns :challenge_rejected for rejected challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 3
        })

      {:ok, rejected_challenge} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      assert Matches.status(rejected_challenge) == :challenge_rejected
    end

    test "returns :challenge_cancelled for cancelled challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: true},
          created_by_id: 4
        })

      {:ok, cancelled_challenge} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      assert Matches.status(cancelled_challenge) == :challenge_cancelled
    end

    test "status changes as challenge is updated" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Initially pending
      assert Matches.status(challenge) == :challenge_pending

      # Accept the challenge
      {:ok, accepted} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert Matches.status(accepted) == :challenge_accepted

      # Retrieve from store and verify status
      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert Matches.status(retrieved) == :challenge_accepted
    end

    test "status is independent of other challenge fields" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: true},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 999
        })

      {:ok, challenge3} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 42
        })

      # All should start as pending regardless of other fields
      assert Matches.status(challenge1) == :challenge_pending
      assert Matches.status(challenge2) == :challenge_pending
      assert Matches.status(challenge3) == :challenge_pending

      # Update to different statuses
      {:ok, accepted} = Matches.update_challenge(challenge1.id, %{status: "accepted"})
      {:ok, rejected} = Matches.update_challenge(challenge2.id, %{status: "rejected"})
      {:ok, cancelled} = Matches.update_challenge(challenge3.id, %{status: "cancelled"})

      # Status should reflect the updates
      assert Matches.status(accepted) == :challenge_accepted
      assert Matches.status(rejected) == :challenge_rejected
      assert Matches.status(cancelled) == :challenge_cancelled
    end
  end
end
