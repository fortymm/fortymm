defmodule FortymmWeb.ChallengeLive.Show do
  use FortymmWeb, :live_view

  alias Fortymm.Matches
  alias FortymmWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto px-4 py-8">
        <div class="bg-base-200 rounded-2xl shadow-2xl p-8">
          <%!-- Header --%>
          <div class="flex items-center gap-4 mb-8">
            <.icon name="hero-trophy" class="size-12 text-primary flex-shrink-0" />
            <div class="text-left">
              <h1 class="text-4xl font-bold mb-1">Challenge Details</h1>
              <p class="text-lg opacity-75">
                You've been challenged! Review the details below.
              </p>
            </div>
          </div>

          <%!-- Challenge Details --%>
          <div class="w-full max-w-2xl mx-auto space-y-3 mb-8">
            <div class="flex justify-between items-center px-6 py-5 bg-base-300/50 rounded-xl">
              <span class="font-semibold text-lg">Match Length:</span>
              <span class="text-lg">Best of {@challenge.configuration.length_in_games}</span>
            </div>

            <div class="flex justify-between items-center px-6 py-5 bg-base-300/50 rounded-xl">
              <span class="font-semibold text-lg">Match Type:</span>
              <span class="flex items-center gap-2">
                <%= if @challenge.configuration.rated do %>
                  <span class="badge badge-primary badge-lg">Rated</span>
                <% else %>
                  <span class="badge badge-ghost badge-lg">Unrated</span>
                <% end %>
              </span>
            </div>
          </div>

          <%!-- Actions --%>
          <div class="flex flex-col sm:flex-row justify-center gap-3 w-full max-w-2xl mx-auto">
            <button phx-click="decline_challenge" class="btn btn-error btn-outline btn-lg">
              <.icon name="hero-x-mark" class="size-5" /> Decline
            </button>

            <button phx-click="accept_challenge" class="btn btn-success btn-lg">
              <.icon name="hero-check" class="size-5" /> Accept Challenge
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Matches.get_challenge(id) do
      {:ok, challenge} ->
        current_user = socket.assigns.current_scope.user
        maybe_redirect_or_show(socket, challenge, current_user)

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("accept_challenge", _params, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    challenge_id = socket.assigns.challenge.id

    case Matches.accept_challenge(challenge_id, current_user_id) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge accepted!")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, changeset} ->
        error_message = format_acceptance_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_message)}
    end
  end

  @impl true
  def handle_event("decline_challenge", _params, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    challenge_id = socket.assigns.challenge.id

    case Matches.reject_challenge(challenge_id, current_user_id) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge declined")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, changeset} ->
        error_message = format_rejection_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, error_message)}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    # Presence tracking is happening but we don't need to update the UI
    {:noreply, socket}
  end

  @impl true
  def handle_info({:challenge_updated, challenge}, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    socket =
      case {status, is_creator} do
        # Still pending: update the challenge
        {:challenge_pending, false} ->
          assign(socket, :challenge, challenge)

        # Any other case: apply common redirect logic
        _ ->
          socket
          |> apply_status_redirect(challenge, status, is_creator)
          |> elem(1)
      end

    {:noreply, socket}
  end

  defp maybe_redirect_or_show(socket, challenge, current_user) do
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user.id

    case {status, is_creator} do
      # Pending: creator redirected to waiting room
      {:challenge_pending, true} ->
        {:ok,
         socket
         |> put_flash(:info, "View the waiting room to see who's checking out your challenge")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}

      # Pending: non-creator can see show page
      {:challenge_pending, false} ->
        topic = "challenge:#{challenge.id}"

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Fortymm.PubSub, topic)

          {:ok, _} =
            Presence.track(self(), topic, current_user.id, %{
              username: current_user.username,
              joined_at: System.system_time(:second)
            })
        end

        socket =
          socket
          |> assign(:challenge, challenge)

        {:ok, socket}

      # Accepted: creator redirected to scoring
      {:challenge_accepted, true} ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! Time to enter scores")
         |> push_navigate(to: ~p"/matches/#{challenge.id}/games/1/scores/new")}

      # Common redirects: use utility function
      _ ->
        apply_status_redirect(socket, challenge, status, is_creator)
    end
  end

  defp apply_status_redirect(socket, challenge, status, is_creator) do
    case {status, is_creator} do
      # Accepted: non-creator redirected to match page
      {:challenge_accepted, false} ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! The match has begun")
         |> push_navigate(to: ~p"/matches/#{challenge.id}")}

      # Cancelled: anyone redirected to dashboard
      {:challenge_cancelled, _} ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been cancelled")
         |> push_navigate(to: ~p"/dashboard")}

      # Rejected: anyone redirected to dashboard
      {:challenge_rejected, _} ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been declined")
         |> push_navigate(to: ~p"/dashboard")}

      # Any other case: redirect to waiting room
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge status changed")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}
    end
  end

  defp format_acceptance_errors(changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

    cond do
      Map.has_key?(errors, :acceptor_id) ->
        "You cannot accept your own challenge"

      Map.has_key?(errors, :challenge) ->
        challenge_error = errors.challenge |> List.first()
        "This challenge #{challenge_error}"

      true ->
        "Failed to accept challenge. Please try again."
    end
  end

  defp format_rejection_errors(changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

    cond do
      Map.has_key?(errors, :rejector_id) ->
        "You cannot decline your own challenge"

      Map.has_key?(errors, :challenge) ->
        challenge_error = errors.challenge |> List.first()
        "This challenge #{challenge_error}"

      true ->
        "Failed to decline challenge. Please try again."
    end
  end
end
