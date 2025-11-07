defmodule Fortymm.Matches.ChallengeAcceptance do
  @moduledoc """
  Embedded schema for validating challenge acceptance.

  This schema codifies the business rules for accepting a challenge:
  - The challenge must be in "pending" status
  - The acceptor must be different from the creator
  - All required fields must be present

  This is not persisted to the database but used for validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.Challenge

  embedded_schema do
    embeds_one :challenge, Challenge
    field :acceptor_id, :integer
  end

  @doc """
  Creates a changeset for a ChallengeAcceptance.

  Validates that:
  - The challenge is required and embedded
  - The acceptor_id is required
  - The challenge status is "pending"
  - The acceptor_id is different from the challenge creator

  ## Examples

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "pending"}
      iex> changeset(%ChallengeAcceptance{}, %{challenge: challenge, acceptor_id: 2})
      %Ecto.Changeset{valid?: true}

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "accepted"}
      iex> changeset(%ChallengeAcceptance{}, %{challenge: challenge, acceptor_id: 2})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(acceptance, attrs) do
    challenge = Map.get(attrs, :challenge)

    acceptance
    |> cast(attrs, [:acceptor_id])
    |> put_embed(:challenge, challenge)
    |> validate_required([:acceptor_id, :challenge])
    |> validate_challenge_is_pending()
    |> validate_acceptor_is_not_creator()
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

  defp validate_acceptor_is_not_creator(changeset) do
    challenge = get_field(changeset, :challenge)
    acceptor_id = get_field(changeset, :acceptor_id)

    case {challenge, acceptor_id} do
      {%Challenge{created_by_id: creator_id}, acceptor_id}
      when not is_nil(creator_id) and creator_id == acceptor_id ->
        add_error(changeset, :acceptor_id, "cannot accept your own challenge")

      _ ->
        changeset
    end
  end
end
