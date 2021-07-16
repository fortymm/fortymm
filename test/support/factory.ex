defmodule Fortymm.Factory do
  use ExMachina.Ecto, repo: Fortymm.Repo

  def player_factory do
    %Fortymm.Players.Player{
      first_name: sequence(:player_first_name, &"player_first_name-#{&1}"),
      last_name: sequence(:player_last_name, &"player_last_name-#{&1}")
    }
  end
end
