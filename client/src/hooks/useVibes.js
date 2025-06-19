"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useJoinVibe = exports.useCreateVibe = exports.useVibeBlips = exports.useEmergingVibes = exports.useVibes = void 0;
const react_query_1 = require("@tanstack/react-query");
const vibes_1 = require("../api/vibes");
const useVibes = () => {
    return (0, react_query_1.useQuery)({
        queryKey: ['vibes'],
        queryFn: vibes_1.vibesApi.getVibes,
    });
};
exports.useVibes = useVibes;
const useEmergingVibes = () => {
    return (0, react_query_1.useQuery)({
        queryKey: ['vibes', 'emerging'],
        queryFn: vibes_1.vibesApi.getEmergingVibes,
        refetchInterval: 10000, // Refresh every 10 seconds to see progress
    });
};
exports.useEmergingVibes = useEmergingVibes;
const useVibeBlips = (vibeUri) => {
    return (0, react_query_1.useQuery)({
        queryKey: ['vibes', vibeUri, 'blips'],
        queryFn: () => vibes_1.vibesApi.getVibeBlips(vibeUri),
        enabled: !!vibeUri,
    });
};
exports.useVibeBlips = useVibeBlips;
const useCreateVibe = () => {
    const queryClient = (0, react_query_1.useQueryClient)();
    return (0, react_query_1.useMutation)({
        mutationFn: vibes_1.vibesApi.createVibe,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vibes'] });
        },
    });
};
exports.useCreateVibe = useCreateVibe;
const useJoinVibe = () => {
    const queryClient = (0, react_query_1.useQueryClient)();
    return (0, react_query_1.useMutation)({
        mutationFn: ({ vibeUri, cid }) => vibes_1.vibesApi.joinVibe(vibeUri, cid),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vibes'] });
        },
    });
};
exports.useJoinVibe = useJoinVibe;
