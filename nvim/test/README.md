# NVIM Config

## Why would I use Neovim ?

When VSCode an Intellij exists, why would I use such an "archaic" text editor ?

I have used VSCode for years and Intellij for almost a year by now and they are extraordinary good IDE. 
BUT when you are working on a 2019 Mac Book pro with only 8Go of memory running Chrome, docker, Java... It ain't enough and something will crash at some point.
And here comes my redemption: Neovim.

A light weight, blazingly fast, HIGHLY customizable and extendable text editor.
I firstly used NvChad for its completeness (and to be honest the name attract me quite a bit ;) ).

I had the pleasure to discover such amazing tools:
 - quickfix list: a simple list that can contain anything: symbols, files, references, etc. And you can perform any action on (macros)
 - telescope: a fuzzy finder for many resources such as symbols, text, files, etc coming with many features
 - git integration: navigating and working with hunks :ok_hand:
 - lsp: ok it is not only for Neovim but only there you got such control over your lsp
 - macros: they are so fast and useful in some situation, mind blowing
 - memory friendly: thanks to the Lazy plugin, you chose when plugins are loading in memory. Take some notes JetBrain...
 - configuration in Lua: for some it can be a red flag, but quite funny and always enjoyable to learn a new language I think

It took me a few days to understand all keybindings and possible action with vim. But was sooo enjoyable to navigate through the code with such ease. And when coming back to a standard IDE, discovered what the PrimeAgent call "the search fatigue": always looking for a resource, file or symbole. Within Neovim it is extremely fluid to search something, beautiful.
But with time I wanted some feature that I was missing (some specific lsp or configs) and the customization/maintainability was not so great within NvChad and did not understand what I was doing at that time.
So I restarted from scratch with `kickstart.nvim`, and started to love it! Added some plugins, some lsp, and then the config started to get messy. The `init.lua` was horrible to work with and here we are after some time of reflexion and using Intellij as my main IDE professionally for 3 months I now know what I need and want for my dev environment.

Of course Neovim will NOT replace Intellij (their refactoring tools are way too good and for now unmatched). In the same way it will NOT replace VSCode.

Secondly using Neovim force you to understand more deeply your dev environment such as LSP, terminal, swap, processes, concurrency, all tools provided by your IDE, env variables, runtimes, etc. And it remind you that Kotlin has terrible tooling (it has been created by JetBrains and official LSP/tooling are only in Intellij!!!), in comparison Golang has one of the best tooling as far as I tested :metal:.


## Feature Needed

It will be a mix of Intellij, and my previous experiences with NvChad and kickstart.

- [x] Plugin Manager -> lazy.nvim
- [x] Key helper -> wichkey.nvim
- [x] highlighting -> treesitter.nvim
- [x] Lsp manager -> mason.nvim + lazydev ?
- [x] Lsp configurator -> lsp-config.nvim
- [x] Auto completion -> nvim-cmp
- [x] Search capabilities -> telescope
- [x] Diagnostic -> nvim + trouble ?
- [x] Snippet -> luasnip + friendly-snippet
- [x] Tmux integration
- [x] consistent formatting -> conform.nvim
- [ ] Themes -> base46
- [x] Utils -> mini.nvim
- [ ] Debugger -> dap
- [x] nerd icon
- [x] File tree ? -> nvim-tree.nvim
- [ ] TSJee 
- [ ] nvim-bqf 
- [x] git management


## Nice to have / Ideas

- [-] spell checker
- [-] spell check with [spelllang](https://neovim.io/doc/user/options.html#'spelllang')
- [ ] telescope search terminal
- [ ] bring an existing zsh session into neovim?
- [ ] bring a running process logs into neovim term?
- [ ] color previewer -> catgoose/nvim-colorizer.lua
- [x] comments todo -> folke/todo-comments.nvim
- [ ] todo list
- [x] 'nvim-treesitter/nvim-treesitter-textobjects'
- [ ] markdown previewer (external or in buffer)
- [ ] preferred files -> harpoon
- [ ] nvim notification ? -> noice.nvim
- [ ] check fzf-lua and lspsaga

### Languages & Tools

- [x] lua
- [x] python
- [x] go
- [x] bash
- [ ] java
  - [ ] kotlin LOL
  - [ ] maven
  - [ ] gradle
- [x]js/ts
  - [x] vue
  - [x] react
  - [x] angular
  - [ ] eslint
  - [ ] prettier
- [x] css/scss
- [x] html

