defmodule Fortymm.Matches.Challenge do
  @moduledoc """
  Embedded schema for a challenge.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.Configuration

  @valid_statuses ["pending", "accepted", "rejected", "cancelled"]

  embedded_schema do
    embeds_one :configuration, Configuration
    field :created_by_id, :integer
    field :status, :string, default: "pending"
    field :match_id, :string
  end

  @doc """
  Creates a changeset for a Challenge.

  ## Examples

      iex> changeset(%Challenge{}, %{configuration: %{length_in_games: 3}})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Challenge{}, %{configuration: %{length_in_games: 2}})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, [:created_by_id, :status, :match_id])
    |> cast_embed(:configuration, required: true)
    |> validate_required([:created_by_id])
    |> validate_inclusion(:status, @valid_statuses,
      message: "must be one of: #{Enum.join(@valid_statuses, ", ")}"
    )
  end
end
