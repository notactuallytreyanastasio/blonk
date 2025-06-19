import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { blipsApi } from '../api/blips'

export const useBlips = () => {
  return useQuery({
    queryKey: ['blips'],
    queryFn: blipsApi.getBlips,
  })
}

export const useBlipsByTag = (tag: string) => {
  return useQuery({
    queryKey: ['blips', 'tag', tag],
    queryFn: () => blipsApi.getBlipsByTag(tag),
    enabled: !!tag,
  })
}

export const useCreateBlip = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: blipsApi.createBlip,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['blips'] })
    },
  })
}