import axios from 'axios'
import type { Vibe, Blip } from './blips'

const API_BASE = '/api'

export interface EmergingVibe {
  vibeName: string
  mentionCount: number
  firstMentioned: string
  lastMentioned: string
  progress: number
}

export const vibesApi = {
  getVibes: async (): Promise<Vibe[]> => {
    const { data } = await axios.get(`${API_BASE}/vibes`)
    return data.vibes
  },

  getEmergingVibes: async (): Promise<EmergingVibe[]> => {
    const { data } = await axios.get(`${API_BASE}/vibes/emerging`)
    return data.emergingVibes
  },

  getVibeBlips: async (vibeUri: string): Promise<Blip[]> => {
    const { data } = await axios.get(`${API_BASE}/vibes/${encodeURIComponent(vibeUri)}/blips`)
    return data.blips
  },

  createVibe: async (vibe: {
    name: string
    mood: string
    emoji?: string
    color?: string
  }) => {
    const { data } = await axios.post(`${API_BASE}/vibes`, vibe)
    return data
  },

  joinVibe: async (vibeUri: string, cid: string) => {
    const { data } = await axios.post(`${API_BASE}/vibes/${encodeURIComponent(vibeUri)}/join`, { cid })
    return data
  },
}