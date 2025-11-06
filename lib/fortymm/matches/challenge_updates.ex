defmodule Fortymm.Matches.ChallengeUpdates do
  @moduledoc """
  PubSub interface for broadcasting and subscribing to challenge updates.
  """

  alias Phoenix.PubSub

  @pubsub Fortymm.PubSub

  @doc """
  Broadcasts a challenge update to all subscribers.

  ## Examples

      iex> broadcast(%Challenge{id: "abc123"})
      :ok

  """
  def broadcast(%{id: id} = challenge) do
    PubSub.broadcast(@pubsub, topic(id), {:challenge_updated, challenge})
  end

  @doc """
  Subscribes the current process to updates for a specific challenge.

  ## Examples

      iex> subscribe("abc123")
      :ok

  """
  def subscribe(challenge_id) do
    PubSub.subscribe(@pubsub, topic(challenge_id))
  end

  defp topic(challenge_id), do: "challenge:#{challenge_id}"
end
