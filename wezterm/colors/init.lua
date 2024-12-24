local M = {}

function M.apply(config, name)
  config.colors = require('colors.' .. name)
end

return M
