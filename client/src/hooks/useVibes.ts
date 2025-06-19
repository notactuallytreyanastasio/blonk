import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { vibesApi } from '../api/vibes'

export const useVibes = () => {
  return useQuery({
    queryKey: ['vibes'],
    queryFn: vibesApi.getVibes,
  })
}

export const useEmergingVibes = () => {
  return useQuery({
    queryKey: ['vibes', 'emerging'],
    queryFn: vibesApi.getEmergingVibes,
    refetchInterval: 10000, // Refresh every 10 seconds to see progress
  })
}

export const useVibeBlips = (vibeUri: string) => {
  return useQuery({
    queryKey: ['vibes', vibeUri, 'blips'],
    queryFn: () => vibesApi.getVibeBlips(vibeUri),
    enabled: !!vibeUri,
  })
}

export const useCreateVibe = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: vibesApi.createVibe,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vibes'] })
    },
  })
}

export const useJoinVibe = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ vibeUri, cid }: { vibeUri: string; cid: string }) => 
      vibesApi.joinVibe(vibeUri, cid),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vibes'] })
    },
  })
}