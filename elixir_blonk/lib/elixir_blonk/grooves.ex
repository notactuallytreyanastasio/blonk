defmodule ElixirBlonk.Grooves do
  @moduledoc """
  The Grooves context.
  """

  import Ecto.Query, warn: false
  alias ElixirBlonk.Repo

  alias ElixirBlonk.Grooves.Groove
  alias ElixirBlonk.Blips

  @doc """
  Creates a groove (reaction) for a blip.
  """
  def create_groove(attrs \\ %{}) do
    # Find the blip by subject_uri if provided
    attrs = if attrs[:subject_uri] do
      case Blips.get_blip_by_uri(attrs[:subject_uri]) do
        nil -> attrs
        blip -> Map.put(attrs, :blip_id, blip.id)
      end
    else
      attrs
    end

    %Groove{}
    |> Groove.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, groove} ->
        # Update groove counts on the blip
        if groove.blip_id do
          Blips.update_groove_counts(groove.blip_id)
        end
        {:ok, groove}
      error -> error
    end
  end

  @doc """
  Deletes a groove.
  """
  def delete_groove(%Groove{} = groove) do
    result = Repo.delete(groove)
    
    # Update groove counts on the blip
    if groove.blip_id do
      Blips.update_groove_counts(groove.blip_id)
    end
    
    result
  end

  @doc """
  Gets a groove by author and subject.
  """
  def get_groove_by_author_and_subject(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> Repo.one()
  end

  @doc """
  Toggles a groove - creates if doesn't exist, changes type if different, deletes if same.
  """
  def toggle_groove(author_did, subject_uri, groove_type, attrs \\ %{}) do
    case get_groove_by_author_and_subject(author_did, subject_uri) do
      nil ->
        # Create new groove
        attrs = Map.merge(attrs, %{
          author_did: author_did,
          subject_uri: subject_uri,
          groove_type: groove_type
        })
        create_groove(attrs)
        
      %Groove{groove_type: ^groove_type} = groove ->
        # Same type, so remove it
        delete_groove(groove)
        {:ok, nil}
        
      groove ->
        # Different type, update it
        groove
        |> Groove.changeset(%{groove_type: groove_type})
        |> Repo.update()
        |> case do
          {:ok, updated_groove} ->
            # Update counts
            if updated_groove.blip_id do
              Blips.update_groove_counts(updated_groove.blip_id)
            end
            {:ok, updated_groove}
          error -> error
        end
    end
  end

  @doc """
  Lists all grooves for a blip.
  """
  def list_grooves_for_blip(blip_id) do
    Groove
    |> where([g], g.blip_id == ^blip_id)
    |> Repo.all()
  end

  @doc """
  Lists all grooves by a specific author.
  """
  def list_grooves_by_author(author_did) do
    Groove
    |> where([g], g.author_did == ^author_did)
    |> preload(:blip)
    |> Repo.all()
  end

  @doc """
  Counts grooves by type for a blip.
  """
  def count_grooves_by_type(blip_id, groove_type) do
    Groove
    |> where([g], g.blip_id == ^blip_id and g.groove_type == ^groove_type)
    |> Repo.aggregate(:count)
  end

  @doc """
  Checks if an author has grooved a specific blip.
  """
  def has_grooved?(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> Repo.exists?()
  end

  @doc """
  Gets the groove type for an author on a specific blip.
  """
  def get_groove_type(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> select([g], g.groove_type)
    |> Repo.one()
  end
end