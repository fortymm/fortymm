defmodule Fortymm.Matches.ChallengeRejection do
  @moduledoc """
  Embedded schema for validating challenge rejection.

  This schema codifies the business rules for rejecting a challenge:
  - The challenge must be in "pending" status
  - The rejector must be different from the creator
  - All required fields must be present

  This is not persisted to the database but used for validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.Challenge

  embedded_schema do
    embeds_one :challenge, Challenge
    field :rejector_id, :integer
  end

  @doc """
  Creates a changeset for a ChallengeRejection.

  Validates that:
  - The challenge is required and embedded
  - The rejector_id is required
  - The challenge status is "pending"
  - The rejector_id is different from the challenge creator

  ## Examples

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "pending"}
      iex> changeset(%ChallengeRejection{}, %{challenge: challenge, rejector_id: 2})
      %Ecto.Changeset{valid?: true}

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "accepted"}
      iex> changeset(%ChallengeRejection{}, %{challenge: challenge, rejector_id: 2})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(rejection, attrs) do
    challenge = Map.get(attrs, :challenge)

    rejection
    |> cast(attrs, [:rejector_id])
    |> put_embed(:challenge, challenge)
    |> validate_required([:rejector_id, :challenge])
    |> validate_challenge_is_pending()
    |> validate_rejector_is_not_creator()
  end

  defp validate_challenge_is_pending(changeset) do
    case get_field(changeset, :challenge) do
      %Challenge{status: "pending"} ->
        changeset

      %Challenge{status: status} ->
        add_error(changeset, :challenge, "must be pending, but is #{status}")

      nil ->
        changeset
    end
  end

  defp validate_rejector_is_not_creator(changeset) do
    challenge = get_field(changeset, :challenge)
    rejector_id = get_field(changeset, :rejector_id)

    case {challenge, rejector_id} do
      {%Challenge{created_by_id: creator_id}, rejector_id}
      when not is_nil(creator_id) and creator_id == rejector_id ->
        add_error(changeset, :rejector_id, "cannot reject your own challenge")

      _ ->
        changeset
    end
  end
end
