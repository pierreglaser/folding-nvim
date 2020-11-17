local lsp =vim.lsp
local api=vim.api

local M = {}

-- TODO: per-buffer fold table?
M.current_buf_folds = {}

-- Informative table keeping track of language servers that implement textDocument/foldingRange.
-- Not used at runtime (capability is resolved dynamically)
M.servers_supporting_folding = {
  pyls = true,
  sumneko_lua = true,
  texlab = true,
  clangd = false,
  julials = false,
}

M.done_clients = {}


function M.on_attach()
  M.setup_plugin()
  M.update_folds()
end


function M.setup_plugin()
  local clients = vim.lsp.buf_get_clients()

  for _, client in pairs(clients) do
    local client_id = client['id']
    if M.done_clients[client_id] == nil then
      local server_supports_folding = client['server_capabilities']['foldingRangeProvider'] or false


      if server_supports_folding then
        client.config.handlers['textDocument/foldingRange'] = M.fold_handler
        api.nvim_command('augroup LspFolding')
        api.nvim_command('autocmd!')
        api.nvim_command('autocmd BufWritePost <buffer> lua require"folding".update_folds()')
        api.nvim_command('autocmd InsertLeave <buffer> lua require"folding".update_folds()')
        api.nvim_command('augroup END')

        local current_window = api.nvim_get_current_win()
        api.nvim_win_set_option(current_window, 'foldmethod', 'expr')
        api.nvim_win_set_option(current_window, 'foldexpr', 'folding_nvim#foldexpr()')
      else
        api.nvim_command(string.format('echom "lsp-folding: %s does not provide folding requests"', client['name']))
      end

      M.done_clients[client_id] = server_supports_folding
    end
  end
end


function M.update_folds()
  local clients = lsp.buf_get_clients(0)
  for client_id, _ in pairs(clients) do
    if M.done_clients[client_id] then
      lsp.buf_request(0, 'textDocument/foldingRange', {textDocument = lsp.util.make_text_document_params()})
    end
  end
end


function M.debug_folds()
  for _, table in ipairs(M.current_buf_folds) do
    local start_line = table['startLine']
    local end_line = table['endLine']
    print('startline', start_line, 'endline', end_line)
  end
end


function M.fold_handler(_, _, result)
  for _, fold in ipairs(result) do
    fold['startLine'] = M.adjust_foldstart(fold['startLine'])
    fold['endLine'] = M.adjust_foldend(fold['endLine'])
  end

  table.sort(result, function(a, b) return a['startLine']  < b['startLine'] end)
  M.current_buf_folds = result
  local current_window = api.nvim_get_current_win()
  api.nvim_win_set_option(current_window, 'foldmethod', 'expr')
end


function M.adjust_foldstart(line_no)
  return line_no + 1
end


function M.adjust_foldend(line_no)
  local bufnr = api.nvim_get_current_buf()
  local filetype = api.nvim_buf_get_option(bufnr, 'filetype')
  if filetype == 'lua' then
    return line_no + 2
  else
    return line_no + 1
  end
end


function M.get_fold_indic(lnum)
  local fold_level = 0
  local is_foldstart = false
  local is_foldend = false

  for _, table in ipairs(M.current_buf_folds) do
    local start_line = table['startLine']
    local end_line = table['endLine']

    -- can exit early b/c folds get pre-orderered manually
    if lnum < start_line then
      break
    end

    if lnum >= start_line and lnum <= end_line then
      fold_level = fold_level + 1
      if lnum == start_line then
        is_foldstart = true
      end
      if lnum == end_line then
        is_foldend = true
      end
    end
  end

  if is_foldend and is_foldstart then
    -- If line marks both start and end of folds (like ``else`` statement),
    -- merge the two folds into one by returning the current foldlevel
    -- without any marker.
    return fold_level
  elseif is_foldstart then
    return string.format(">%d", fold_level)
  elseif is_foldend then
    return string.format("<%d", fold_level)
  else
    return fold_level
  end

end


return M
