LSP-Powered folding plugin for neovim.


# Requirements

Neovim nightly, `nvim_lsp` as well as the language servers you want to use this plugin with.


# Installation

Install this plugin using your favorite package manager, or clone the source code inside
`/path_to_nvim_config_folder/pack/opt/*/` where `*` stands fot the standard wildcard.


Example (assuming your plugins are stored inside `~/.config/nvim/pack/github/opt`)
```sh
git clone https://github.com/pierreglaser/folding-nvim ~/.config/nvim/pack/github/opt/folding-nvim
```

And make sure the plugin is loaded at initialization by placing the following inside your `init.vim`

```vim
packadd folding-nvim
```

# Configuration

Neovim needs to add the `folding.on_attach` callback to each language server you want to use this plugin with. For instance, for
`palantir/python-language-server`, add those following lua lines to your `vimrc`:
```lua
lua << EOF
function on_attach_callback(client, bufnr)
  -- If you use completion-nvim/diagnostic-nvim, uncomment those two lines.
  -- require('diagnostic').on_attach()
  -- require('completion').on_attach()
  require('folding').on_attach()
end

require'nvim_lsp'.pyls.setup{on_attach=on_attach_callback}
EOF
```


# LICENCE

BSD 3-Clause Licence.
