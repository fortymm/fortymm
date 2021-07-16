defmodule Fortymm.LeagueMemberships.LeagueMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Players.Player
  alias Fortymm.Leagues.League

  schema "league_memberships" do
    field :external_league_ref, :string
    belongs_to :league, League
    belongs_to :player, Player

    timestamps()
  end

  @doc false
  def changeset(league_membership, attrs) do
    league_membership
    |> cast(attrs, [:external_league_ref, :league_id, :player_id])
    |> validate_required([:league_id, :player_id])
  end
end
