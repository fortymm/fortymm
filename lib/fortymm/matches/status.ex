defmodule Fortymm.Matches.Status do
  @moduledoc """
  Determines the status of a challenge for routing and display purposes.
  """

  alias Fortymm.Matches.Challenge

  @doc """
  Returns the status of a challenge.

  ## Returns

  - `:challenge_pending` - Challenge is pending acceptance
  - `:challenge_accepted` - Challenge has been accepted
  - `:challenge_rejected` - Challenge has been rejected
  - `:challenge_cancelled` - Challenge has been cancelled

  ## Examples

      iex> for_challenge(%Challenge{status: "pending"})
      :challenge_pending

      iex> for_challenge(%Challenge{status: "accepted"})
      :challenge_accepted

      iex> for_challenge(%Challenge{status: "rejected"})
      :challenge_rejected

      iex> for_challenge(%Challenge{status: "cancelled"})
      :challenge_cancelled

  """
  def for_challenge(%Challenge{status: "pending"}), do: :challenge_pending
  def for_challenge(%Challenge{status: "accepted"}), do: :challenge_accepted
  def for_challenge(%Challenge{status: "rejected"}), do: :challenge_rejected
  def for_challenge(%Challenge{status: "cancelled"}), do: :challenge_cancelled
end
