defmodule ElixirBlonk.Vibes do
  @moduledoc """
  The Vibes context for managing topic-based communities in the Blonk ecosystem.
  
  Vibes are the heart of Blonk's community organization - interest-based feeds where
  users submit blips and engage through grooves. This context manages the organic
  creation, discovery, and growth of community spaces through grassroots engagement.
  
  ## What Are Vibes?
  
  **Vibes are community-driven topic feeds:**
  - Interest-based communities (e.g., art_vibe, tech_vibe, music_vibe)
  - Created organically through #vibe-name mentions reaching critical mass
  - Contain blips relevant to the community's focus
  - Enable targeted audience engagement and content discovery
  - Form the foundation for radar trending and cross-vibe connections
  
  ## Organic Community Creation
  
  **Vibes emerge naturally from community interest:**
  1. **Mention Phase**: Users post content with #vibe-name hashtags
  2. **Accumulation**: System tracks mentions across the firehose
  3. **Critical Mass**: Once threshold is reached, vibe officially emerges
  4. **Community Growth**: Members join, submit blips, and engage through grooves
  5. **Radar Integration**: Popular vibe content surfaces on the frontpage
  
  ## Blonk Ecosystem Integration
  
  - **Blips**: Content submissions that give vibes their substance
  - **Grooves**: Community engagement that drives vibe activity
  - **Tags**: Universal labels that connect content across vibes
  - **Radar**: Popular vibe content surfaces on the frontpage
  - **Hot Posts**: AI-curated content seeds engagement in new vibes
  
  ## Community Philosophy
  
  **Vibes prioritize authentic community formation:**
  - No top-down vibe creation - communities must emerge organically
  - Interest-based rather than algorithm-driven organization
  - Quality content rises through peer grooves, not engagement manipulation
  - Cross-vibe discovery through universal tags promotes healthy growth
  - Real community engagement over vanity metrics
  
  ## Vibe Lifecycle
  
  1. **Grassroots Mentions**: Users naturally reference #vibe-topics in posts
  2. **Threshold Detection**: Firehose consumer tracks mention accumulation
  3. **Emergence**: Vibe officially created when community interest is proven
  4. **Content Submission**: Users submit relevant blips to the new vibe
  5. **Community Engagement**: Members groove on content, driving activity
  6. **Radar Visibility**: Popular content attracts new members
  
  ## Membership and Engagement
  
  **Flexible community participation:**
  - Users can join multiple vibes based on interests
  - Member counts visible for community size indication
  - Activity levels drive vibe prominence on radar
  - Tag frequency analysis reveals community interests
  - Cross-vibe connections through shared tags and members
  
  ## Discovery Mechanisms
  
  **Multiple pathways for vibe discovery:**
  - Emerging vibes list shows communities gaining momentum
  - Tag-based discovery reveals related vibes
  - Radar trending surfaces popular vibe content
  - Member activity patterns suggest relevant communities
  
  ## Examples
  
      # Track a potential new vibe
      Vibes.record_vibe_mention(%{
        vibe_name: "art",
        author_did: "did:plc:user123",
        post_uri: "at://did:plc:user123/app.bsky.feed.post/rkey",
        mentioned_at: DateTime.utc_now()
      })
      
      # Check if vibe has reached emergence threshold
      case Vibes.check_vibe_emergence("art") do
        {:emerging, vibe} -> 
          # New community has formed!
        {:not_ready, count} -> 
          # Still accumulating mentions: #{count}
      end
      
      # Get vibe content for radar
      popular_blips = Blips.list_blips_by_vibe(art_vibe.uri)
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.Vibes.{Vibe, VibeMember, VibeMention}

  @doc """
  Returns the list of vibes.
  """
  def list_vibes do
    Repo.all(Vibe)
  end

  @doc """
  Returns the list of vibes ordered by pulse score.
  """
  def list_vibes_by_pulse do
    Vibe
    |> order_by([v], desc: v.pulse_score)
    |> Repo.all()
  end

  @doc """
  Returns the list of emerging vibes.
  """
  def list_emerging_vibes do
    Vibe
    |> where([v], v.is_emerging == true)
    |> order_by([v], desc: v.pulse_score)
    |> Repo.all()
  end

  @doc """
  Gets a single vibe.
  """
  def get_vibe!(id), do: Repo.get!(Vibe, id)

  @doc """
  Gets a vibe by URI.
  """
  def get_vibe_by_uri(uri) do
    Repo.get_by(Vibe, uri: uri)
  end

  @doc """
  Gets a vibe by name.
  """
  def get_vibe_by_name(name) do
    Repo.get_by(Vibe, name: name)
  end

  @doc """
  Creates a vibe.
  """
  def create_vibe(attrs \\ %{}) do
    # First create in local database
    with {:ok, vibe} <- %Vibe{}
                        |> Vibe.changeset(attrs)
                        |> Repo.insert() do
      
      # Then try to create in ATProto if enabled
      if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
        Task.Supervisor.start_child(ElixirBlonk.TaskSupervisor, fn ->
          create_vibe_in_atproto(vibe)
        end)
      end
      
      {:ok, vibe}
    end
  end

  defp create_vibe_in_atproto(vibe) do
    with {:ok, client} <- ElixirBlonk.ATProto.SessionManager.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.Client.create_vibe(client, vibe) do
      
      # Update local record with ATProto URI and CID
      update_vibe(vibe, %{uri: uri, cid: cid})
      Logger.info("Created vibe in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create vibe in ATProto: #{inspect(reason)}")
    end
  end

  @doc """
  Updates a vibe.
  """
  def update_vibe(%Vibe{} = vibe, attrs) do
    vibe
    |> Vibe.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a vibe.
  """
  def delete_vibe(%Vibe{} = vibe) do
    Repo.delete(vibe)
  end

  @doc """
  Joins a user to a vibe.
  """
  def join_vibe(member_did, vibe_id, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{
      member_did: member_did,
      vibe_id: vibe_id
    })

    %VibeMember{}
    |> VibeMember.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, member} ->
        update_member_count(vibe_id)
        {:ok, member}
      error -> error
    end
  end

  @doc """
  Checks if a user is a member of a vibe.
  """
  def is_member?(member_did, vibe_uri) do
    VibeMember
    |> where([vm], vm.member_did == ^member_did and vm.vibe_uri == ^vibe_uri)
    |> Repo.exists?()
  end

  @doc """
  Updates the member count for a vibe.
  """
  def update_member_count(vibe_id) do
    count = VibeMember
    |> where([vm], vm.vibe_id == ^vibe_id)
    |> Repo.aggregate(:count)

    vibe = Repo.get!(Vibe, vibe_id)
    update_vibe(vibe, %{member_count: count})
  end

  @doc """
  Records a vibe mention.
  """
  def record_vibe_mention(attrs) do
    %VibeMention{}
    |> VibeMention.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, mention} ->
        check_and_formalize_vibe(mention.vibe_name)
        {:ok, mention}
      error -> error
    end
  end

  @doc """
  Checks if a vibe should be formalized based on mention thresholds.
  """
  def check_and_formalize_vibe(vibe_name) do
    unique_authors = VibeMention
    |> where([vm], vm.vibe_name == ^vibe_name)
    |> distinct([vm], vm.author_did)
    |> Repo.aggregate(:count)

    total_mentions = VibeMention
    |> where([vm], vm.vibe_name == ^vibe_name)
    |> Repo.aggregate(:count)

    if unique_authors >= 5 or total_mentions >= 10 do
      unless get_vibe_by_name(vibe_name) do
        case create_vibe(%{
          uri: "at://blonk.app/vibe/#{vibe_name}",
          cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
          creator_did: "did:plc:blonk",
          name: vibe_name,
          mood: vibe_name,
          is_emerging: false
        }) do
          {:ok, vibe} ->
            # Broadcast the emergence
            Phoenix.PubSub.broadcast(
              ElixirBlonk.PubSub,
              "vibes:emerged",
              {:vibe_emerged, vibe}
            )
            {:ok, vibe}
          error -> error
        end
      end
    end
  end

  @doc """
  Gets vibe mention statistics.
  """
  def get_vibe_mention_stats do
    VibeMention
    |> group_by([vm], vm.vibe_name)
    |> select([vm], %{
      vibe_name: vm.vibe_name,
      total_mentions: count(vm.id),
      unique_authors: count(fragment("DISTINCT ?", vm.author_did))
    })
    |> Repo.all()
  end

  @doc """
  Updates pulse scores for all vibes based on recent activity.
  """
  def update_pulse_scores do
    # This would be called periodically to update vibe pulse scores
    # based on recent blip activity, member count, etc.
    # Implementation depends on specific scoring algorithm
  end
end