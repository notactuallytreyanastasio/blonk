import axios from 'axios'

const API_BASE = '/api'

export interface Vibe {
  uri: string
  cid: string
  creatorDid: string
  name: string
  mood: string
  emoji?: string
  color?: string
  memberCount: number
  createdAt: string
}

export interface Blip {
  uri: string
  cid: string
  authorDid: string
  authorHandle?: string
  authorDisplayName?: string
  title: string
  body?: string
  url?: string
  tags?: string[]
  vibeUri?: string
  vibeName?: string
  createdAt: string
  grooves: number
}

export const blipsApi = {
  getBlips: async (): Promise<Blip[]> => {
    const { data } = await axios.get(`${API_BASE}/blips`)
    return data.blips
  },

  getBlipsByTag: async (tag: string): Promise<Blip[]> => {
    const { data } = await axios.get(`${API_BASE}/blips/tag/${tag}`)
    return data.blips
  },

  createBlip: async (blip: {
    title: string
    body?: string
    url?: string
    tags: string[]
    vibe?: {
      uri: string
      cid: string
      name?: string
    }
  }) => {
    const { data } = await axios.post(`${API_BASE}/blips`, blip)
    return data
  },
}