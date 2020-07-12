function! folding_nvim#foldexpr()
  return luaeval(printf('require"folding".get_fold_indic(%d)', v:lnum))
endfunction
