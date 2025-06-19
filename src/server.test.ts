import { BlonkAgent } from './agent';
import { BlipManager } from './blips';
import { VibeManager } from './vibes';
import { BlipAggregator } from './firehose';
import { SearchMonitor } from './search-monitor';
import { blipDb, vibeDb, vibeMentionDb } from './database';

// Mock all dependencies
jest.mock('./agent');
jest.mock('./blips');
jest.mock('./vibes');
jest.mock('./firehose');
jest.mock('./search-monitor');
jest.mock('./database');
jest.mock('dotenv', () => ({
  config: jest.fn()
}));

describe('Blonk Server Unit Tests', () => {
  let mockAgent: jest.Mocked<BlonkAgent>;
  let mockBlipManager: jest.Mocked<BlipManager>;
  let mockVibeManager: jest.Mocked<VibeManager>;
  let mockAggregator: jest.Mocked<BlipAggregator>;
  let mockSearchMonitor: jest.Mocked<SearchMonitor>;
  let mockBlipDb: any;
  let mockVibeDb: any;
  let mockVibeMentionDb: any;

  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
    
    // Set up mock instances
    mockAgent = {
      login: jest.fn().mockResolvedValue(undefined),
      getAgent: jest.fn().mockReturnValue({
        session: { did: 'did:plc:test123' },
        com: {
          atproto: {
            repo: {
              createRecord: jest.fn()
            }
          }
        }
      })
    } as any;

    mockBlipManager = {
      createBlip: jest.fn().mockResolvedValue('at://did:plc:test/app.bsky.feed.post/abc123')
    } as any;

    mockVibeManager = {
      joinVibe: jest.fn().mockResolvedValue(undefined),
      createVibe: jest.fn().mockResolvedValue('at://did:plc:test/vibe/xyz789')
    } as any;

    mockAggregator = {
      startPolling: jest.fn(),
      addUser: jest.fn()
    } as any;

    mockSearchMonitor = {
      start: jest.fn().mockResolvedValue(undefined),
      searchForVibeMentions: jest.fn().mockResolvedValue(undefined)
    } as any;

    // Set up database mocks
    mockBlipDb = {
      getBlips: jest.fn().mockReturnValue([]),
      getBlipsByVibe: jest.fn().mockReturnValue([]),
      getBlipsByTag: jest.fn().mockReturnValue([]),
      addBlip: jest.fn()
    };

    mockVibeDb = {
      getVibes: jest.fn().mockReturnValue([]),
      addMember: jest.fn(),
      getVibe: jest.fn()
    };

    mockVibeMentionDb = {
      getEmergingVibes: jest.fn().mockReturnValue([]),
      getVibeByName: jest.fn(),
      recordMention: jest.fn()
    };

    // Set up mocked constructors
    (BlonkAgent as jest.MockedClass<typeof BlonkAgent>).mockImplementation(() => mockAgent);
    (BlipManager as jest.MockedClass<typeof BlipManager>).mockImplementation(() => mockBlipManager);
    (VibeManager as jest.MockedClass<typeof VibeManager>).mockImplementation(() => mockVibeManager);
    (BlipAggregator as jest.MockedClass<typeof BlipAggregator>).mockImplementation(() => mockAggregator);
    (SearchMonitor as jest.MockedClass<typeof SearchMonitor>).mockImplementation(() => mockSearchMonitor);
    
    // Replace database exports with mocks
    (blipDb as any) = mockBlipDb;
    (vibeDb as any) = mockVibeDb;
    (vibeMentionDb as any) = mockVibeMentionDb;
  });

  describe('Component Initialization', () => {
    it('should create BlonkAgent instance', () => {
      const agent = new BlonkAgent();
      expect(BlonkAgent).toHaveBeenCalled();
      expect(agent).toBe(mockAgent);
    });

    it('should login to BlonkAgent', async () => {
      const agent = new BlonkAgent();
      await agent.login();
      expect(mockAgent.login).toHaveBeenCalled();
    });

    it('should create BlipManager with agent instance', () => {
      const agentInstance = mockAgent.getAgent();
      const manager = new BlipManager(agentInstance);
      expect(BlipManager).toHaveBeenCalledWith(agentInstance);
      expect(manager).toBe(mockBlipManager);
    });

    it('should create VibeManager with agent instance', () => {
      const agentInstance = mockAgent.getAgent();
      const manager = new VibeManager(agentInstance);
      expect(VibeManager).toHaveBeenCalledWith(agentInstance);
      expect(manager).toBe(mockVibeManager);
    });

    it('should create BlipAggregator with agent instance', () => {
      const agentInstance = mockAgent.getAgent();
      const aggregator = new BlipAggregator(agentInstance);
      expect(BlipAggregator).toHaveBeenCalledWith(agentInstance);
      expect(aggregator).toBe(mockAggregator);
    });

    it('should start polling on BlipAggregator', () => {
      const aggregator = new BlipAggregator(mockAgent.getAgent());
      aggregator.startPolling(30000);
      expect(mockAggregator.startPolling).toHaveBeenCalledWith(30000);
    });

    it('should create SearchMonitor with agent instance', () => {
      const agentInstance = mockAgent.getAgent();
      const monitor = new SearchMonitor(agentInstance);
      expect(SearchMonitor).toHaveBeenCalledWith(agentInstance);
      expect(monitor).toBe(mockSearchMonitor);
    });

    it('should start SearchMonitor', async () => {
      const monitor = new SearchMonitor(mockAgent.getAgent());
      await monitor.start();
      expect(mockSearchMonitor.start).toHaveBeenCalled();
    });
  });

  describe('BlipManager Operations', () => {
    it('should create blip with all parameters', async () => {
      const title = 'Test Title';
      const body = 'Test Body';
      const url = 'https://example.com';
      const tags = ['tag1', 'tag2'];
      const vibe = 'at://vibe/uri';

      const uri = await mockBlipManager.createBlip(title, body, url, tags, vibe);

      expect(uri).toBe('at://did:plc:test/app.bsky.feed.post/abc123');
      expect(mockBlipManager.createBlip).toHaveBeenCalledWith(title, body, url, tags, vibe);
    });

    it('should handle blip creation errors', async () => {
      mockBlipManager.createBlip.mockRejectedValue(new Error('Creation failed'));

      await expect(
        mockBlipManager.createBlip('Title', 'Body', 'url', [], undefined)
      ).rejects.toThrow('Creation failed');
    });
  });

  describe('VibeManager Operations', () => {
    it('should join vibe successfully', async () => {
      const vibeUri = 'at://vibe/uri';
      const cid = 'cid123';

      await mockVibeManager.joinVibe(vibeUri, cid);

      expect(mockVibeManager.joinVibe).toHaveBeenCalledWith(vibeUri, cid);
    });

    it('should handle join vibe errors', async () => {
      mockVibeManager.joinVibe.mockRejectedValue(new Error('Join failed'));

      await expect(
        mockVibeManager.joinVibe('at://vibe/uri', 'cid123')
      ).rejects.toThrow('Join failed');
    });

    it('should create vibe successfully', async () => {
      const name = 'test_vibe';
      const mood = 'chill';
      const emoji = '🎵';
      const color = '#FF0000';

      const uri = await mockVibeManager.createVibe(name, mood, emoji, color);

      expect(uri).toBe('at://did:plc:test/vibe/xyz789');
      expect(mockVibeManager.createVibe).toHaveBeenCalledWith(name, mood, emoji, color);
    });
  });

  describe('Database Operations', () => {
    describe('BlipDb', () => {
      it('should get blips with limit', () => {
        const mockBlips = [
          { id: '1', title: 'Blip 1' },
          { id: '2', title: 'Blip 2' }
        ];
        mockBlipDb.getBlips.mockReturnValue(mockBlips);

        const result = mockBlipDb.getBlips(50);

        expect(result).toEqual(mockBlips);
        expect(mockBlipDb.getBlips).toHaveBeenCalledWith(50);
      });

      it('should get blips by vibe', () => {
        const vibeUri = 'at://vibe/uri';
        const mockBlips = [{ id: '1', title: 'Vibe Blip' }];
        mockBlipDb.getBlipsByVibe.mockReturnValue(mockBlips);

        const result = mockBlipDb.getBlipsByVibe(vibeUri);

        expect(result).toEqual(mockBlips);
        expect(mockBlipDb.getBlipsByVibe).toHaveBeenCalledWith(vibeUri);
      });

      it('should get blips by tag', () => {
        const tag = 'test-tag';
        const mockBlips = [{ id: '1', title: 'Tagged Blip' }];
        mockBlipDb.getBlipsByTag.mockReturnValue(mockBlips);

        const result = mockBlipDb.getBlipsByTag(tag);

        expect(result).toEqual(mockBlips);
        expect(mockBlipDb.getBlipsByTag).toHaveBeenCalledWith(tag);
      });
    });

    describe('VibeDb', () => {
      it('should get vibes with limit', () => {
        const mockVibes = [
          { uri: 'at://vibe1', name: 'Vibe 1' },
          { uri: 'at://vibe2', name: 'Vibe 2' }
        ];
        mockVibeDb.getVibes.mockReturnValue(mockVibes);

        const result = mockVibeDb.getVibes(50);

        expect(result).toEqual(mockVibes);
        expect(mockVibeDb.getVibes).toHaveBeenCalledWith(50);
      });

      it('should add member to vibe', () => {
        const vibeUri = 'at://vibe/uri';
        const memberDid = 'did:plc:member';

        mockVibeDb.addMember(vibeUri, memberDid);

        expect(mockVibeDb.addMember).toHaveBeenCalledWith(vibeUri, memberDid);
      });
    });

    describe('VibeMentionDb', () => {
      it('should get emerging vibes', () => {
        const mockEmergingVibes = [
          { hashtag: '#vibe-test', count: 7, uniqueAuthors: 5 },
          { hashtag: '#vibe-demo', count: 5, uniqueAuthors: 5 }
        ];
        mockVibeMentionDb.getEmergingVibes.mockReturnValue(mockEmergingVibes);

        const result = mockVibeMentionDb.getEmergingVibes();

        expect(result).toEqual(mockEmergingVibes);
        expect(mockVibeMentionDb.getEmergingVibes).toHaveBeenCalled();
      });
    });
  });

  describe('BlipAggregator Operations', () => {
    it('should add user to aggregation', () => {
      const did = 'did:plc:newuser';
      
      mockAggregator.addUser(did);

      expect(mockAggregator.addUser).toHaveBeenCalledWith(did);
    });
  });

  describe('SearchMonitor Operations', () => {
    it('should search for vibe mentions', async () => {
      await mockSearchMonitor.searchForVibeMentions();

      expect(mockSearchMonitor.searchForVibeMentions).toHaveBeenCalled();
    });

    it('should handle search errors', async () => {
      mockSearchMonitor.searchForVibeMentions.mockRejectedValue(new Error('Search failed'));

      await expect(
        mockSearchMonitor.searchForVibeMentions()
      ).rejects.toThrow('Search failed');
    });
  });

  describe('Error Scenarios', () => {
    it('should handle database errors gracefully', () => {
      mockBlipDb.getBlips.mockImplementation(() => {
        throw new Error('Database connection failed');
      });

      expect(() => mockBlipDb.getBlips(50)).toThrow('Database connection failed');
    });

    it('should handle missing agent session', () => {
      mockAgent.getAgent.mockReturnValue({
        session: null
      } as any);

      const agentInstance = mockAgent.getAgent();
      expect(agentInstance.session).toBeNull();
    });
  });

  describe('Integration Flow', () => {
    it('should complete full blip creation flow', async () => {
      // Initialize agent
      const agent = new BlonkAgent();
      await agent.login();

      // Create manager
      const blipManager = new BlipManager(agent.getAgent());

      // Create blip
      const uri = await blipManager.createBlip(
        'Integration Test',
        'Testing full flow',
        'https://test.com',
        ['integration', 'test'],
        undefined
      );

      expect(uri).toBe('at://did:plc:test/app.bsky.feed.post/abc123');
      expect(mockAgent.login).toHaveBeenCalled();
      expect(mockBlipManager.createBlip).toHaveBeenCalled();
    });

    it('should complete full vibe join flow', async () => {
      // Initialize agent
      const agent = new BlonkAgent();
      await agent.login();

      // Create manager
      const vibeManager = new VibeManager(agent.getAgent());

      // Join vibe
      await vibeManager.joinVibe('at://vibe/uri', 'cid123');

      // Add member to database
      mockVibeDb.addMember('at://vibe/uri', 'did:plc:test123');

      expect(mockVibeManager.joinVibe).toHaveBeenCalledWith('at://vibe/uri', 'cid123');
      expect(mockVibeDb.addMember).toHaveBeenCalledWith('at://vibe/uri', 'did:plc:test123');
    });
  });
});