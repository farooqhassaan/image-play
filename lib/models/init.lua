local M = {}

function M.setup(opt, checkpoint)
  local Model = require('lib/models/' .. opt.netType)

  -- Get output dim
  local Dataset = require('lib/datasets/' .. opt.dataset)
  local dataset = Dataset(opt, 'train')
  local outputDim = dataset.part:size(2)

  -- Create model
  local model = Model.createModel(opt, outputDim)

  -- Load hourglass
  local model_hg
  if opt.hgModel ~= 'none' then
    assert(paths.filep(opt.hgModel),
        'initial hourglass model not found: ' .. opt.hgModel)
    model_hg = torch.load(opt.hgModel)
    Model.loadHourglass(model, model_hg)
  end

  -- Create criterion
  local criterion = nn.ParallelCriterion()
  for i = 1, opt.seqLength do
    criterion:add(nn.MSECriterion())
  end

  -- Convert to CUDA
  -- TODO: handle CPU case
  model:cuda()
  criterion:cuda()

  return model, criterion
end

return M