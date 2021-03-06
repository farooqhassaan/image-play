
local M = {}

-------------------------------------------------------------------------------
-- Helpful functions for evaluation
-------------------------------------------------------------------------------

function M.calcDists(preds, label, normalize)
    local dists = torch.Tensor(preds:size(2), preds:size(1))
    local diff = torch.Tensor(2)
    for i = 1,preds:size(1) do
        for j = 1,preds:size(2) do
            if label[i][j][1] ~= 0 and label[i][j][2] ~= 0 then
                dists[j][i] = torch.dist(label[i][j],preds[i][j])/normalize[i]
            else
                dists[j][i] = -1
            end
        end
    end
    return dists
end

function M.getPreds(hm)
    assert(hm:size():size() == 4, 'Input must be 4-D tensor')
    local max, idx = torch.max(hm:view(hm:size(1), hm:size(2), hm:size(3) * hm:size(4)), 3)
    local preds = torch.repeatTensor(idx, 1, 1, 2):float()
    preds[{{}, {}, 1}]:apply(function(x) return (x - 1) % hm:size(4) + 1 end)
    -- bug: hm:size(3) -> hm:size(4)?
    preds[{{}, {}, 2}]:add(-1):div(hm:size(3)):floor():add(1)
    return preds, max
end

function M.distAccuracy(dists, thr)
    -- Return percentage below threshold while ignoring values with a -1
    if not thr then thr = .5 end
    if torch.ne(dists,-1):sum() > 0 then
        return dists:le(thr):eq(dists:ne(-1)):sum() / dists:ne(-1):sum()
    else
        return -1
    end
end

function M.heatmapAccuracy(output, label, thr, idxs, outputRes)
    -- Calculate accuracy according to PCK, but uses ground truth heatmap rather than x,y locations
    -- First value to be returned is average accuracy across 'idxs', followed by individual accuracies
    local preds = M.getPreds(output)
    local gt = M.getPreds(label)
    local dists = M.calcDists(preds, gt, torch.ones(preds:size(1))*outputRes/10)
    local acc = {}
    local avgAcc = 0.0
    local badIdxCount = 0

    if not idxs then
        for i = 1,dists:size(1) do
            acc[i+1] = M.distAccuracy(dists[i])
            if acc[i+1] >= 0 then avgAcc = avgAcc + acc[i+1]
            else badIdxCount = badIdxCount + 1 end
        end
        acc[1] = avgAcc / (dists:size(1) - badIdxCount)
    else
        for i = 1,#idxs do
            acc[i+1] = M.distAccuracy(dists[idxs[i]])
            if acc[i+1] >= 0 then avgAcc = avgAcc + acc[i+1]
            else badIdxCount = badIdxCount + 1 end
        end
        acc[1] = avgAcc / (#idxs - badIdxCount)
    end
    return unpack(acc)
end

function M.coordAccuracy(output, label, thr, idxs, outputRes, ref)
    local dists = M.calcDists(output, label, ref)
    local acc = {}
    local avgAcc = 0.0
    local badIdxCount = 0

    if not idxs then
        for i = 1,dists:size(1) do
            acc[i+1] = M.distAccuracy(dists[i], thr)
            if acc[i+1] >= 0 then avgAcc = avgAcc + acc[i+1]
            else badIdxCount = badIdxCount + 1 end
        end
        acc[1] = avgAcc / (dists:size(1) - badIdxCount)
    else
        for i = 1,#idxs do
            acc[i+1] = M.distAccuracy(dists[idxs[i]], thr)
            if acc[i+1] >= 0 then avgAcc = avgAcc + acc[i+1]
            else badIdxCount = badIdxCount + 1 end
        end
        acc[1] = avgAcc / (#idxs - badIdxCount)
    end

    local pos, tot
    if not idxs then
        tot = dists:ne(-1):sum()
        pos = dists:le(thr):eq(dists:ne(-1)):sum()
    else
        local dist_ = dists:index(1,torch.LongTensor(idxs))
        tot = dist_:ne(-1):sum()
        pos = dist_:le(thr):eq(dist_:ne(-1)):sum()
    end
    return pos, tot, unpack(acc)
end

return M