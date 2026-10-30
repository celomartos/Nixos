# Atalhos Neovim (Nixvim)

`<leader>` é `\`. Não há `mapleader`/`maplocalleader` personalizado. `n`: normal; `i`: inserção; `v`: visual; `o`: operador-pendente; `t`: terminal. Mapas de plugins valem no contexto indicado. Padrões do plugin são distintos dos mapas definidos nesta configuração.

## LSP

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `gd` | `n` | Ir à definição |
| `gr` | `n` | Buscar referências |
| `K` | `n` | Mostrar documentação do símbolo |
| `<leader>rn` | `n` | Renomear símbolo |
| `<leader>ca` | `n` | Ações de código |

## Navegação e busca

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `<leader>ff` | `n` | Telescope: buscar arquivos |
| `<leader>fg` | `n` | Telescope: busca textual no projeto |
| `<leader>j` | `n`, `v`, `o` | Flash: busca rápida |
| `<leader>J` | `n`, `v`, `o` | Flash: busca por Treesitter |
| `r` | `o` | Flash: movimento remoto |
| `<leader>sd` | `n` | Abrir dashboard Snacks |
| `f` / `g` / `r` / `n` / `t` / `s` / `q` | Dashboard | Buscar arquivos / buscar texto / recentes / novo arquivo / temas / restaurar sessão / sair |

## Explorer e pickers

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `<CR>` / `l` | Explorer / picker | Abrir/confirmar item; no Explorer, entrar no diretório |
| `h` / `<BS>` | Explorer | Fechar diretório / subir um nível |
| `a` / `r` | Explorer | Criar arquivo ou diretório / renomear item |
| `c` / `m` | Explorer | Copiar / mover item selecionado; sem seleção, `c` copia item atual e `m` renomeia |
| `d` / `U` | Explorer | Enviar à lixeira (confirme com Enter) / desfazer exclusão elegível |
| `y` / `p` | Explorer (`y`: `n`/`v`) | Copiar caminho(s) / colar itens copiados |
| `o` | Explorer | Abrir com aplicativo do sistema |
| `<Tab>` / `<S-Tab>` | Explorer / picker | Alternar seleção e avançar / retroceder |
| `u` / `P` | Explorer | Atualizar árvore / alternar preview |
| `H` / `I` / `Z` | Explorer | Alternar ocultos / ignorados / fechar diretórios |
| `.` / `<C-c>` / `<C-t>` | Explorer | Definir diretório da aba / definir diretório da aba / abrir terminal no diretório |
| `<leader>/` | Explorer | Buscar texto no diretório |
| `]g` / `[g` | Explorer | Próximo / anterior item com mudança Git |
| `]d` / `[d`, `]e` / `[e`, `]w` / `[w` | Explorer | Próximo/anterior diagnóstico, erro ou aviso |
| `<CR>` | Picker | Abrir resultado |
| `<C-n>` / `<C-p>` | Picker | Próximo / anterior resultado |
| `<C-x>` / `<C-v>` / `<C-t>` | Telescope | Abrir em split horizontal / vertical / nova aba |
| `<C-s>` / `<C-v>` / `<C-t>` | Snacks picker | Abrir em split horizontal / vertical / nova aba |
| `<Esc>` / `<C-c>` | Picker | Cancelar; tecla/mode variam entre Snacks e Telescope |

## Edição e snippets

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `gcc` / `gbc` | `n` | Comment.nvim: alternar comentário de linha / bloco |
| `gc{movimento}` / `gb{movimento}` | `n`, `o`; seleção `v` | Comentar linha / bloco sobre movimento ou seleção |
| `gco` / `gcO` / `gcA` | `n` | Inserir comentário abaixo / acima / no fim da linha |
| `sa` / `sd` / `sr` | mini.surround: `sa` em `n`/`v`; `sd`/`sr` em `n` | Adicionar / remover / substituir surround |
| `sf` / `sF` / `sh` | `n` | mini.surround: encontrar à direita / à esquerda / realçar surround |
| `<C-l>` / `<C-h>` | `i` | Próximo / anterior campo do snippet |
| `main` | Snippet LuaSnip em C/C++ | Expandir esqueleto da função principal; texto de expansão, não atalho de teclado |
| `<C-Space>` | `i` | Abrir conclusão |
| `<C-n>` / `<C-p>` | `i` | Próxima / anterior sugestão |
| `<C-e>` | `i` | Fechar conclusão |
| `<CR>` | `i` | Aceitar sugestão; seleciona primeiro item se nenhum selecionado |

## Git

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `]h` / `[h`, `]c` / `[c` | `n`, buffer com Gitsigns | Próximo / anterior hunk; em diff, `]c`/`[c` usam navegação nativa |
| `<leader>hp` / `<leader>hd` | `n`, buffer com Gitsigns | Preview do hunk / diff inline |
| `<leader>hD` | `n`, buffer com Gitsigns | Diff do arquivo contra HEAD |
| `<leader>hr` | `n` / `v`, buffer com Gitsigns | Resetar hunk / linhas selecionadas |
| `<leader>hR` | `n`, buffer com Gitsigns | Resetar buffer inteiro |
| `<leader>hb` / `<leader>hB` | `n`, buffer com Gitsigns | Histórico/blame da linha / alternar blame virtual |
| `<leader>hq` | `n`, buffer com Gitsigns | Enviar hunks ao Quickfix |

## Diagnósticos e listas

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `<leader>e` | `n` | Mostrar diagnóstico sob o cursor |
| `<leader>xx` / `<leader>xX` | `n` | Alternar todos os diagnósticos / diagnósticos do buffer |
| `<leader>cs` / `<leader>cl` | `n` | Alternar símbolos / navegação LSP |
| `<leader>xL` / `<leader>xQ` | `n` | Alternar lista local / Quickfix via Trouble |
| `<leader>co` | `n` | Abrir Quickfix nativo com 8 linhas |
| `<leader>xt` | `n` | Alternar lista TODO/FIXME |
| `<Esc>` | `n` | Fechar Trouble se aberto; caso contrário, limpar realce da busca |
| `<Esc>` | `n`, janela Trouble | Fechar Trouble |
| `<CR>` / `o` / `q` | Janela Trouble | Ir ao item / ir e fechar / fechar |
| `?` / `r` / `R` | Janela Trouble | Ajuda / atualizar / alternar atualização automática |
| `]]` / `[[` | Janela Trouble | Próximo / anterior item |
| `<C-s>` / `<C-v>` | Janela Trouble | Abrir item em split horizontal / vertical |
| `dd` / `d` | Janela Trouble (`d` em visual) | Remover item / remover seleção da lista |

## Execução e terminal

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `<leader>rr` | `n` | Executar arquivo: C/C++ compila; Cargo executa `cargo run` no projeto; Rust sem Cargo compila com `rustc`; Lua executa diretamente |
| `<leader>tt` | `n` | Alternar painel ToggleTerm horizontal |
| `<leader>tt` | `t`, terminal integrado | Fechar painel |
| `<Esc>` | `t`, terminal integrado | Sair do modo de entrada do terminal |

## Depuração

| Atalho | Modo/contexto | Ação |
|---|---|---|
| `<leader>dc` / `<leader>db` | `n` | Iniciar/continuar / alternar breakpoint |
| `<leader>dB` | `n` | Definir breakpoint condicional; solicita condição |
| `<leader>dn` / `<leader>di` / `<leader>do` | `n` | Step over / into / out |
| `<leader>dq` | `n` | Encerrar depuração e fechar painel DAP UI |
| `<leader>du` | `n` | Alternar painel DAP UI |
| `<leader>de` | `n`, `v` | Avaliar expressão sob o cursor / seleção |
| `<leader>dh` / `<leader>ds` | `n` | Inspecionar variável / mostrar escopos |

## Sessões e comandos

| Atalho/comando | Modo/contexto | Ação |
|---|---|---|
| `<leader>qs` / `<leader>ql` / `<leader>qd` | `n` | Restaurar sessão do diretório atual / última sessão / apagar sessão atual |
| `:RunCurrentFile` | Comando | Mesmo que `<leader>rr` |
| `:NixvimThemePicker` | Comando | Abrir seletor de temas |
| `:map` / `:nmap` / `:imap` / `:tmap` | Comandos | Listar mapas / mapas normais / inserção / terminal |
| `:verbose nmap <leader>ff` | Comando | Mostrar mapa e origem; troque modo e tecla conforme necessário |
| `:Telescope keymaps` | Comando | Pesquisar mapas no Telescope |
| `\` e aguardar | `n`, Which-Key | Abrir menu de mapas após atraso padrão |

`nvim-autopairs` insere pares automaticamente; não define mapa próprio nesta configuração. Não há atalho de salvamento personalizado.
