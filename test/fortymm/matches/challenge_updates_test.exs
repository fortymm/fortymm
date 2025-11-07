defmodule Fortymm.Matches.ChallengeUpdatesTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.{Challenge, ChallengeUpdates, Configuration}

  describe "subscribe/1" do
    test "subscribes to challenge updates" do
      challenge_id = "test123"
      assert :ok = ChallengeUpdates.subscribe(challenge_id)
    end

    test "allows multiple subscriptions to the same challenge" do
      challenge_id = "test456"
      assert :ok = ChallengeUpdates.subscribe(challenge_id)
      assert :ok = ChallengeUpdates.subscribe(challenge_id)
    end
  end

  describe "broadcast/1" do
    test "broadcasts challenge update to subscribers" do
      challenge = %Challenge{
        id: "broadcast123",
        configuration: %Configuration{length_in_games: 3, rated: false},
        created_by_id: 1,
        status: "pending"
      }

      ChallengeUpdates.subscribe(challenge.id)
      assert :ok = ChallengeUpdates.broadcast(challenge)

      assert_receive {:challenge_updated, ^challenge}
    end

    test "only subscribers receive the broadcast" do
      challenge = %Challenge{
        id: "broadcast456",
        configuration: %Configuration{length_in_games: 5, rated: true},
        created_by_id: 2,
        status: "accepted"
      }

      # Don't subscribe to this challenge
      assert :ok = ChallengeUpdates.broadcast(challenge)

      refute_receive {:challenge_updated, ^challenge}, 100
    end

    test "broadcasts to multiple subscribers" do
      challenge = %Challenge{
        id: "broadcast789",
        configuration: %Configuration{length_in_games: 7, rated: false},
        created_by_id: 3,
        status: "rejected"
      }

      # Subscribe from the test process
      ChallengeUpdates.subscribe(challenge.id)

      # Spawn another process and subscribe from there
      parent = self()

      spawn(fn ->
        ChallengeUpdates.subscribe(challenge.id)
        send(parent, :subscribed)

        receive do
          msg -> send(parent, {:child_received, msg})
        after
          1000 -> send(parent, :child_timeout)
        end
      end)

      # Wait for child to subscribe
      assert_receive :subscribed

      # Broadcast the update
      assert :ok = ChallengeUpdates.broadcast(challenge)

      # Both processes should receive the message
      assert_receive {:challenge_updated, ^challenge}
      assert_receive {:child_received, {:challenge_updated, ^challenge}}
    end

    test "does not broadcast to subscribers of different challenges" do
      challenge1 = %Challenge{
        id: "challenge1",
        configuration: %Configuration{length_in_games: 3, rated: false},
        created_by_id: 1,
        status: "pending"
      }

      challenge2 = %Challenge{
        id: "challenge2",
        configuration: %Configuration{length_in_games: 5, rated: true},
        created_by_id: 2,
        status: "accepted"
      }

      # Subscribe only to challenge1
      ChallengeUpdates.subscribe(challenge1.id)

      # Broadcast challenge2
      assert :ok = ChallengeUpdates.broadcast(challenge2)

      # Should not receive challenge2 update
      refute_receive {:challenge_updated, ^challenge2}, 100
    end

    test "broadcasts include all challenge fields" do
      challenge = %Challenge{
        id: "full_challenge",
        configuration: %Configuration{length_in_games: 5, rated: true},
        created_by_id: 42,
        status: "accepted"
      }

      ChallengeUpdates.subscribe(challenge.id)
      assert :ok = ChallengeUpdates.broadcast(challenge)

      assert_receive {:challenge_updated, received_challenge}
      assert received_challenge.id == "full_challenge"
      assert received_challenge.configuration.length_in_games == 5
      assert received_challenge.configuration.rated == true
      assert received_challenge.created_by_id == 42
      assert received_challenge.status == "accepted"
    end
  end
end
