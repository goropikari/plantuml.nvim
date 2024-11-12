local encoder = require('plantuml.encoder')

local M = {}

local state = {
  bufnr = -1,
  winid = -1,
  paths = {},
}

local default_config = {
  base_url = 'https://www.plantuml.com/plantuml',
  reload_events = { 'BufWritePre' },
  viewer = 'xdg-open',
}
local config = {}

function M.setup(opts)
  state.bufnr = vim.api.nvim_create_buf(false, true)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
end

local function _generate_ascii(encode_data)
  if not vim.api.nvim_win_is_valid(state.winid) then
    state.winid = vim.api.nvim_open_win(state.bufnr, false, {
      split = 'right',
      style = 'minimal',
    })
    vim.api.nvim_set_option_value('wrap', false, { win = state.winid })
  end

  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, {})

  local cmd = { 'curl', '-s', config.base_url .. '/txt/' .. encode_data }
  vim.system(cmd, {}, function(obj)
    if obj.code ~= 0 then
      vim.notify('failed to generate ascii', vim.log.levels.WARN)
      return
    end
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, vim.fn.split(obj.stdout, '\n'))
    end)
  end)
end

local function _generate_image(encode_data, ext, path, callback)
  ext = ext or 'png'
  path = path or vim.fn.tempname() .. '_plantuml.' .. ext

  local bufnr_str = tostring(vim.api.nvim_get_current_buf())
  local prevpath = vim.tbl_get(state, 'paths', bufnr_str, ext)
  if prevpath == nil then
    state = vim.tbl_deep_extend('force', state, { paths = { [bufnr_str] = { [ext] = path } } })
  else
    path = prevpath
  end

  local cmd = { 'curl', '-s', config.base_url .. '/' .. ext .. '/' .. encode_data, '-o', path }
  vim.system(cmd, {}, function(obj)
    if obj.code == 0 then
      if callback == nil then
        print(path)
      else
        callback(path)
      end
    end
  end)
end

local function get_encode_data()
  local bufnr = vim.api.nvim_get_current_buf()
  local data = vim.fn.join(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  return encoder.encode(data)
end

local function generate_ascii()
  _generate_ascii(get_encode_data())
end

vim.api.nvim_create_user_command('PlantumlPreview', function(opts)
  if opts.args == '' or opts.args == 'ascii' then
    generate_ascii()
    vim.api.nvim_create_autocmd(config.reload_events, {
      buffer = vim.api.nvim_get_current_buf(),
      callback = generate_ascii,
    })
  else
    _generate_image(get_encode_data(), opts.args, nil, function(path)
      vim.system({ config.viewer, path })
    end)
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('PlantumlExport', function(opts)
  local args = vim.split(opts.args, ' ', { trimempty = true })
  if #args == 0 or opts.args[1] == 'ascii' then
    _generate_image(get_encode_data(), 'txt')
  else
    _generate_image(get_encode_data(), args[1], args[2])
  end
end, { nargs = '?' })

vim.api.nvim_create_user_command('PlantumlStartDocker', function(opts)
  vim.system({
    'docker',
    'run',
    '-d',
    '--rm',
    'plantuml/plantuml-server:tomcat',
  }, {}, function(obj)
    if obj.code ~= 0 then
      vim.notify('failed to run plantuml container', vim.log.levels.WARN)
      return
    end

    local container_id = vim.trim(obj.stdout)
    vim.schedule(function()
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          vim.system({ 'docker', 'stop', container_id }):wait()
        end,
      })
    end)

    vim.system({
      'docker',
      'inspect',
      container_id,
      '--format',
      'json',
    }, {}, function(obj2)
      if obj2.code ~= 0 then
        vim.notify('failed to get ip address', vim.log.levels.WARN)
        return
      end
      local res = vim.json.decode(obj2.stdout)
      local ip = res[1].NetworkSettings.IPAddress
      config.base_url = 'http://' .. ip .. ':8080'
    end)
  end)
end, {})

function M.show()
  vim.print(config)
  vim.print(state)
end

return M
