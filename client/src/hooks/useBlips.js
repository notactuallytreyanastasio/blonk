"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useCreateBlip = exports.useBlipsByTag = exports.useBlips = void 0;
const react_query_1 = require("@tanstack/react-query");
const blips_1 = require("../api/blips");
const useBlips = () => {
    return (0, react_query_1.useQuery)({
        queryKey: ['blips'],
        queryFn: blips_1.blipsApi.getBlips,
    });
};
exports.useBlips = useBlips;
const useBlipsByTag = (tag) => {
    return (0, react_query_1.useQuery)({
        queryKey: ['blips', 'tag', tag],
        queryFn: () => blips_1.blipsApi.getBlipsByTag(tag),
        enabled: !!tag,
    });
};
exports.useBlipsByTag = useBlipsByTag;
const useCreateBlip = () => {
    const queryClient = (0, react_query_1.useQueryClient)();
    return (0, react_query_1.useMutation)({
        mutationFn: blips_1.blipsApi.createBlip,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['blips'] });
        },
    });
};
exports.useCreateBlip = useCreateBlip;
