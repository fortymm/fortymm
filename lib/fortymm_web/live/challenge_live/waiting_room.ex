defmodule FortymmWeb.ChallengeLive.WaitingRoom do
  use FortymmWeb, :live_view

  alias Fortymm.Matches
  alias FortymmWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto px-4 py-8">
        <div class="bg-base-200 rounded-2xl shadow-2xl p-8">
          <%!-- Header with loading indicator --%>
          <div class="flex items-center gap-4 mb-8">
            <%!-- Animated waiting indicator --%>
            <div class="relative w-16 h-16 flex-shrink-0">
              <div class="absolute inset-0 rounded-full border-4 border-primary/20"></div>
              <div class="absolute inset-0 rounded-full border-4 border-primary border-t-transparent animate-spin">
              </div>
              <div class="absolute inset-0 flex items-center justify-center">
                <.icon name="hero-trophy" class="size-8 text-primary" />
              </div>
            </div>

            <div class="text-left">
              <h2 class="text-3xl font-bold mb-1">Waiting for Opponent</h2>
              <p class="text-base opacity-75">
                Challenge sent! We're waiting for your opponent to accept.
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

            <div class="flex justify-between items-center px-6 py-5 bg-base-300/50 rounded-xl">
              <span class="font-semibold text-lg">Viewers:</span>
              <span>
                <%= if @viewers == [] do %>
                  <span class="text-base-content/60">No one yet...</span>
                <% else %>
                  <div class="flex flex-wrap gap-2 justify-end">
                    <%= for viewer <- @viewers do %>
                      <span class="badge badge-success badge-lg gap-2">
                        <.icon name="hero-eye" class="size-4" />
                        {viewer}
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </span>
            </div>
          </div>

          <%!-- Share URL --%>
          <div class="w-full max-w-2xl mx-auto mb-8">
            <h3 class="text-xl font-semibold mb-4 text-center">Share this challenge</h3>
            <div class="flex gap-2 mb-6">
              <input
                type="text"
                readonly
                value={url(~p"/challenges/#{@challenge.id}")}
                class="input input-bordered w-full font-mono text-sm bg-base-300/50"
                id="challenge-url"
              />
              <button
                type="button"
                class="btn btn-primary btn-square"
                phx-hook="Copy"
                data-target="#challenge-url"
                id="copy-button"
                title="Copy to clipboard"
              >
                <.icon name="hero-clipboard-document" class="size-5" />
              </button>
            </div>
            <div :if={@qr_code} class="flex justify-center">
              <div class="bg-white p-4 rounded-xl shadow-xl">
                {raw(@qr_code)}
              </div>
            </div>
          </div>

          <%!-- Actions --%>
          <div class="flex flex-col sm:flex-row justify-center gap-4 w-full max-w-2xl mx-auto">
            <button class="btn btn-error btn-outline btn-lg" phx-click="cancel_challenge">
              <.icon name="hero-x-mark" class="size-5" /> Cancel Challenge
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
        current_user_id = socket.assigns.current_scope.user.id
        maybe_redirect_or_show(socket, challenge, current_user_id)

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    topic = "challenge:#{socket.assigns.challenge.id}"
    {:noreply, assign(socket, :viewers, list_viewers(topic))}
  end

  @impl true
  def handle_info({:challenge_updated, challenge}, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    socket =
      case {status, is_creator} do
        # Still pending: update the challenge
        {:challenge_pending, true} ->
          assign(socket, :challenge, challenge)

        # Any other case: apply common redirect logic
        _ ->
          socket
          |> apply_status_redirect(challenge, status, is_creator)
          |> elem(1)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_challenge", _params, socket) do
    current_user_id = socket.assigns.current_scope.user.id

    case Matches.cancel_challenge(socket.assigns.challenge.id, current_user_id) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge cancelled")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cancel challenge. Please try again.")}
    end
  end

  defp list_viewers(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {_user_id, %{metas: [meta | _]}} -> meta.username end)
  end

  defp generate_qr_code(url) do
    settings = %QRCode.Render.SvgSettings{
      scale: 6,
      background_color: "#ffffff",
      qrcode_color: "#000000"
    }

    case url
         |> QRCode.create()
         |> QRCode.render(:svg, settings) do
      {:ok, svg} -> svg
      {:error, _reason} -> nil
    end
  end

  defp maybe_redirect_or_show(socket, challenge, current_user_id) do
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    case {status, is_creator} do
      # Pending: creator can see waiting room
      {:challenge_pending, true} ->
        topic = "challenge:#{challenge.id}"

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Fortymm.PubSub, topic)
        end

        challenge_url = url(socket, ~p"/challenges/#{challenge.id}")
        qr_code = generate_qr_code(challenge_url)

        socket =
          socket
          |> assign(:challenge, challenge)
          |> assign(:viewers, list_viewers(topic))
          |> assign(:qr_code, qr_code)

        {:ok, socket}

      # Pending: non-creator redirected to show page
      {:challenge_pending, false} ->
        {:ok,
         socket
         |> put_flash(:info, "View the challenge details to accept or decline")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}")}

      # Common redirects: use utility function
      _ ->
        apply_status_redirect(socket, challenge, status, is_creator)
    end
  end

  defp apply_status_redirect(socket, challenge, status, _is_creator) do
    case status do
      # Accepted: redirect based on participation
      :challenge_accepted ->
        current_user_id = socket.assigns.current_scope.user.id
        redirect_based_on_participation(socket, challenge, current_user_id)

      # Cancelled: anyone redirected to dashboard
      :challenge_cancelled ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been cancelled")
         |> push_navigate(to: ~p"/dashboard")}

      # Rejected: anyone redirected to dashboard
      :challenge_rejected ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been declined")
         |> push_navigate(to: ~p"/dashboard")}

      # Any other case: redirect to show page
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge status changed")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}")}
    end
  end

  defp redirect_based_on_participation(socket, challenge, current_user_id) do
    match_id = challenge.match_id

    if is_nil(match_id) do
      # Error condition: challenge is accepted but no match_id
      {:ok,
       socket
       |> put_flash(:error, "Something went wrong. Please try again.")
       |> push_navigate(to: ~p"/dashboard")}
    else
      redirect_to_match(socket, match_id, current_user_id)
    end
  end

  defp redirect_to_match(socket, match_id, current_user_id) do
    case Matches.get_match(match_id) do
      {:ok, match} ->
        is_participant =
          Enum.any?(match.participants, fn p -> p.user_id == current_user_id end)

        if is_participant do
          {:ok,
           socket
           |> put_flash(:info, "Challenge accepted! Time to enter scores")
           |> push_navigate(to: ~p"/matches/#{match_id}/games/1/scores/new")}
        else
          {:ok,
           socket
           |> put_flash(:info, "Challenge accepted! The match has begun")
           |> push_navigate(to: ~p"/matches/#{match_id}")}
        end

      {:error, :not_found} ->
        # Fallback to match page if match not found
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! The match has begun")
         |> push_navigate(to: ~p"/matches/#{match_id}")}
    end
  end
end
