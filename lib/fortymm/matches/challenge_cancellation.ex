defmodule Fortymm.Matches.ChallengeCancellation do
  @moduledoc """
  Embedded schema for validating challenge cancellation.

  This schema codifies the business rules for cancelling a challenge:
  - The challenge must be in "pending" status
  - The cancellor must be the same as the creator
  - All required fields must be present

  This is not persisted to the database but used for validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.Challenge

  embedded_schema do
    embeds_one :challenge, Challenge
    field :cancellor_id, :integer
  end

  @doc """
  Creates a changeset for a ChallengeCancellation.

  Validates that:
  - The challenge is required and embedded
  - The cancellor_id is required
  - The challenge status is "pending"
  - The cancellor_id is the same as the challenge creator

  ## Examples

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "pending"}
      iex> changeset(%ChallengeCancellation{}, %{challenge: challenge, cancellor_id: 1})
      %Ecto.Changeset{valid?: true}

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "accepted"}
      iex> changeset(%ChallengeCancellation{}, %{challenge: challenge, cancellor_id: 1})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(cancellation, attrs) do
    challenge = Map.get(attrs, :challenge)

    cancellation
    |> cast(attrs, [:cancellor_id])
    |> put_embed(:challenge, challenge)
    |> validate_required([:cancellor_id, :challenge])
    |> validate_challenge_is_pending()
    |> validate_cancellor_is_creator()
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

  defp validate_cancellor_is_creator(changeset) do
    challenge = get_field(changeset, :challenge)
    cancellor_id = get_field(changeset, :cancellor_id)

    case {challenge, cancellor_id} do
      {%Challenge{created_by_id: creator_id}, cancellor_id}
      when not is_nil(creator_id) and not is_nil(cancellor_id) and creator_id != cancellor_id ->
        add_error(changeset, :cancellor_id, "can only cancel your own challenge")

      _ ->
        changeset
    end
  end
end
