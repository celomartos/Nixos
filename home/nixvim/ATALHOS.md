# Atalhos Neovim (Nixvim)

Fonte: módulos `home/nixvim/*.nix` e fontes locais dos plugins instalados. **Configuração explícita** indica mapa definido aqui; **Padrão confirmado** indica mapa conferido no código instalado; **não testado em runtime** indica que não houve teste interativo.

Defaults auditados: Snacks 2.31.0, Trouble 3.7.1, Which-Key 3.17.0, Flash 2.1.0, mini.surround 0.18.0, Comment.nvim 0.8.0 e Telescope instalado. As ações abaixo foram conferidas no código; a interação visual não foi testada.

`<leader>` é `\`: não há `mapleader` ou `maplocalleader` personalizado.

## Explorer

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<CR>` / `l` | Abrir arquivo / confirmar item; em diretório, expandir ou entrar | Padrão confirmado; Snacks 2.31.0, Explorer |
| `h` / `<BS>` | Fechar diretório sob o cursor / subir um nível | Padrão confirmado; Snacks 2.31.0 |
| `a` | Criar arquivo ou diretório | Padrão confirmado; `/` final cria diretório |
| `r` | Renomear item atual | Padrão confirmado; Snacks 2.31.0 |
| `c` | Copiar item(ns) selecionado(s) para diretório atual | Padrão confirmado; sem seleção, pergunta destino para o item atual |
| `m` | Mover itens selecionados para diretório atual | Padrão confirmado; sem seleção, renomeia item atual; pede confirmação ao mover |
| `o` | Abrir com aplicativo do sistema | Padrão confirmado; Snacks 2.31.0 |
| `d` | Mover item(ns) selecionado(s) para a lixeira | Tecla padrão confirmada; ação personalizada. **ENTER** confirma; ESC ou outra tecla cancela |
| `U` | Desfazer uma exclusão | Configuração explícita; restaura um item elegível, do mais recente para o mais antigo, sem sobrescrever destino |
| `y` / `p` | Copiar caminho(s) para o registro / colar itens copiados | Padrão confirmado; `y` aceita modo normal e visual |
| `<Tab>` / `<S-Tab>` | Alternar seleção e avançar / retroceder na lista | Padrão confirmado; picker Snacks |
| `u` / `P` | Atualizar árvore / alternar preview | Padrão confirmado; Snacks 2.31.0 |
| `H` / `I` / `Z` | Alternar ocultos / ignorados / fechar todos os diretórios | Padrão confirmado; Snacks 2.31.0 |
| `.` | Definir diretório do item atual como diretório da aba | Padrão confirmado; Snacks 2.31.0 |
| `<C-c>` / `<C-t>` | Definir diretório da aba / abrir terminal no diretório | Padrão confirmado; Snacks 2.31.0 |
| `<leader>/` | Buscar texto no diretório do Explorer | Padrão confirmado; Snacks 2.31.0 |
| `]g` / `[g` | Próximo / anterior item com mudança Git | Padrão confirmado; Snacks 2.31.0 |
| `]d` / `[d`, `]e` / `[e`, `]w` / `[w` | Próximo/anterior diagnóstico, erro ou aviso | Padrão confirmado; Snacks 2.31.0 |

Histórico persistente em `stdpath("state")/snacks-explorer-trash.json`: caminho original, identificador/caminho na lixeira, horário e tipo. `U` tenta restaurar uma entrada elegível por uso, da mais recente para a mais antiga. Itens ausentes/incompatíveis e falhas permanecem no histórico; conflito de destino interrompe o undo. Sem teste interativo.

## Busca

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>ff` | Buscar arquivos | Configuração explícita; Telescope |
| `<leader>fg` | Busca textual no projeto | Configuração explícita; Telescope live grep |
| `<CR>` | Abrir resultado | Padrão confirmado; Telescope e Snacks picker |
| `<C-n>` / `<C-p>` | Próximo / anterior resultado | Padrão confirmado; Snacks navega lista (normal/visual) ou input (normal/inserção); Telescope move seleção em inserção |
| `<Tab>` / `<S-Tab>` | Alternar seleção e avançar / retroceder | Padrão confirmado; Telescope e Snacks picker |
| `<C-x>` / `<C-v>` / `<C-t>` | Abrir em split horizontal / vertical / nova aba | Padrão confirmado; Telescope |
| `<C-s>` / `<C-v>` / `<C-t>` | Abrir em split horizontal / vertical / nova aba | Padrão confirmado; Snacks picker |
| `<Esc>` / `<C-c>` | Cancelar picker | Padrão confirmado; Snacks `<Esc>` em normal/inserção e `<C-c>` em inserção; Telescope `<Esc>` em normal e `<C-c>` em inserção |

## Dashboard

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>sd` | Abrir dashboard | Configuração explícita |
| `f` / `g` / `r` | Buscar arquivo / texto / arquivo recente | Configuração explícita; botões Snacks Dashboard, abrem pickers Snacks |
| `n` | Criar arquivo novo | Configuração explícita; inicia inserção |
| `t` | Abrir seletor de temas | Configuração explícita; preview ao navegar; ENTER confirma e grava estado; ESC cancela e restaura o tema anterior |
| `s` | Restaurar sessão do diretório atual | Configuração explícita; botão do dashboard chama `persistence.load()` |
| `q` | Sair do Neovim | Configuração explícita; botão do dashboard chama `:qa` |

Oxocarbon segue como padrão; também estão disponíveis Catppuccin, Tokyo Night, Kanagawa e Gruvbox. O seletor `Snacks.picker.colorschemes()` lista os temas disponíveis no runtime. A escolha confirmada fica em `stdpath("state")/nixvim-colorscheme` e é restaurada após carregar plugins. Estado ausente, inválido ou tema indisponível usa Oxocarbon. `:NixvimThemePicker` abre o mesmo seletor. Preview/cancelamento não grava estado.

## LSP

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `gd` / `gr` | Ir à definição / buscar referências | Configuração explícita; modo normal |
| `K` | Mostrar documentação do símbolo | Configuração explícita; modo normal |
| `<leader>rn` | Renomear símbolo | Configuração explícita; modo normal |
| `<leader>ca` | Ações de código | Configuração explícita; modo normal |

## Diagnósticos / Trouble

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>e` | Mostrar diagnóstico sob o cursor | Configuração explícita; modo normal |
| `<leader>xx` / `<leader>xX` | Alternar diagnósticos / diagnósticos do buffer | Configuração explícita; Trouble |
| `<leader>cs` / `<leader>cl` | Alternar símbolos / navegação LSP | Configuração explícita; Trouble |
| `<leader>xL` / `<leader>xQ` | Alternar lista local / quickfix | Configuração explícita; Trouble |
| `<leader>co` | Abrir quickfix com 8 linhas | Configuração explícita; janela quickfix nativa |
| `<leader>xt` | Alternar lista TODO/FIXME | Configuração explícita; Trouble |
| `<Esc>` | Fechar Trouble; se fechado, limpar realce da busca | Configuração explícita; modo normal |
| `<Esc>` | Fechar Trouble | Configuração explícita; modo normal, janela Trouble |
| `<CR>` / `o` / `q` | Ir ao item / ir e fechar / fechar | Padrão confirmado; Trouble 3.7.1 |
| `?` / `r` / `R` | Ajuda / atualizar / alternar atualização automática | Padrão confirmado; Trouble 3.7.1 |
| `]]` / `[[` | Próximo / anterior item | Padrão confirmado; Trouble 3.7.1 |
| `<C-s>` / `<C-v>` | Abrir item em split horizontal / vertical | Padrão confirmado; Trouble 3.7.1 |
| `dd` / `d` | Remover item / remover seleção visual | Padrão confirmado; Trouble 3.7.1; remove da lista, não da lixeira |

## Git

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `]h` / `[h`, `]c` / `[c` | Próximo / anterior hunk | Configuração explícita; buffer com Gitsigns; em diff, `]c`/`[c` usam navegação nativa |
| `<leader>hp` / `<leader>hd` | Preview do hunk / diff inline | Configuração explícita; buffer com Gitsigns |
| `<leader>hD` | Diff do arquivo contra HEAD | Configuração explícita; buffer com Gitsigns |
| `<leader>hr` | Resetar hunk | Configuração explícita; normal ou seleção visual (linhas selecionadas) |
| `<leader>hR` | Resetar buffer inteiro | Configuração explícita; buffer com Gitsigns |
| `<leader>hb` / `<leader>hB` | Histórico/blame da linha / alternar blame virtual | Configuração explícita; buffer com Gitsigns |
| `<leader>hq` | Enviar todos os hunks ao quickfix | Configuração explícita; buffer com Gitsigns |

## Terminal

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>tt` | Alternar painel de terminal | Configuração explícita; modo normal; painel horizontal |
| `<leader>tt` | Fechar painel de terminal | Configuração explícita; modo terminal |
| `<Esc>` | Sair do modo de entrada do terminal | Configuração explícita; modo terminal; permanece no terminal |

## Execução

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>rr` | Executar arquivo atual | Configuração explícita; C/C++ compila antes; Rust verifica/compila antes; Lua executa diretamente |
| `:RunCurrentFile` | Mesmo que `<leader>rr` | Comando personalizado |

## Debug

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>dc` / `<leader>db` | Iniciar/continuar / alternar breakpoint | Configuração explícita; modo normal |
| `<leader>dB` | Definir breakpoint condicional | Configuração explícita; modo normal; solicita condição |
| `<leader>dn` / `<leader>di` / `<leader>do` | Step over / into / out | Configuração explícita; modo normal |
| `<leader>dq` | Encerrar sessão de debug | Configuração explícita; modo normal; fecha painel DAP UI |
| `<leader>du` | Alternar painel DAP UI | Configuração explícita; modo normal |
| `<leader>de` | Avaliar expressão sob o cursor | Configuração explícita; normal ou visual |
| `<leader>dh` / `<leader>ds` | Inspecionar variável / mostrar escopos | Configuração explícita; modo normal |

## Sessões

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>qs` | Restaurar sessão do diretório atual | Configuração explícita; persistence.nvim |
| `<leader>ql` | Restaurar última sessão | Configuração explícita; persistence.nvim |
| `<leader>qd` | Apagar sessão do diretório atual e parar persistência | Configuração explícita; persistence.nvim |
| `:SessionRestore` / `:SessionRestoreLast` / `:SessionDelete` | Restaurar atual / última / apagar atual | Comandos personalizados |
| `s` | Restaurar sessão atual | Botão do dashboard |

## Flash

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<leader>j` | Busca rápida Flash | Configuração explícita; normal, visual e operador-pendente |
| `<leader>J` | Busca Flash por Treesitter | Configuração explícita; normal, visual e operador-pendente |
| `r` | Flash remoto | Configuração explícita; operador-pendente |

## Snippets

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<C-l>` / `<C-h>` | Próximo / anterior campo do snippet | Configuração explícita; modo inserção |
| `main` | Trigger do snippet de função principal | LuaSnip; disponível em C e C++; não é atalho de teclado; aparece como fonte de nvim-cmp |

## Autocomplete

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `<C-Space>` | Abrir conclusão | Configuração explícita; modo inserção |
| `<C-n>` / `<C-p>` | Próxima / anterior sugestão | Configuração explícita; modo inserção |
| `<C-e>` | Fechar conclusão | Configuração explícita; modo inserção |
| `<CR>` | Aceitar sugestão | Configuração explícita; modo inserção; aceita também o primeiro item se nada estiver selecionado |

## Outros

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `gcc` / `gbc` | Alternar comentário de linha / bloco | Padrão confirmado; Comment.nvim 0.8.0, normal |
| `gc{movimento}` / `gb{movimento}` | Comentar linha / bloco sobre movimento | Padrão confirmado; Comment.nvim 0.8.0, normal e operador-pendente; seleção visual aceita `gc`/`gb` |
| `gco` / `gcO` / `gcA` | Inserir comentário abaixo / acima / no fim da linha | Padrão confirmado; Comment.nvim 0.8.0 |
| `sa` / `sd` / `sr` | Adicionar / remover / substituir surround | Padrão confirmado; mini.surround 0.18.0; `sa` em normal/visual, demais em normal |
| `sf` / `sF` / `sh` | Encontrar à direita / à esquerda / realçar surround | Padrão confirmado; mini.surround 0.18.0, normal |

`nvim-autopairs` fecha pares automaticamente após digitação; não define atalho próprio nesta configuração.

## Descobrir atalhos no Neovim

| Atalho | Ação | Contexto/Observações |
|---|---|---|
| `:map` / `:nmap` / `:imap` / `:tmap` | Listar mapeamentos | Todos / normal / inserção / terminal |
| `:verbose nmap <leader>ff` | Mostrar definição e origem de um mapeamento | Troque modo e atalho conforme necessário |
| `:Telescope keymaps` | Pesquisar mapeamentos | Picker Telescope |
| `\` e aguardar | Abrir menu Which-Key | Padrão confirmado; Which-Key 3.17.0 ativa gatilhos automáticos; atraso padrão de 200 ms; modo normal |
