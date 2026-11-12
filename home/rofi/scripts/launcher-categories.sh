#!/usr/bin/env bash

# Define as categorias e os filtros correspondentes
declare -A categories=(
  ["🎮 Jogos"]="Game"
  ["💻 Desenvolvimento"]="Development,IDE,TextEditor"
  ["⚙️ Configurações"]="Settings,Utility"
  ["🌐 Internet"]="Network,WebBrowser"
  ["📁 Acessórios"]="Utility,Accessories"
  ["🎨 Gráficos"]="Graphics,Image,Photo"
)

# Exibe a lista de categorias no Rofi
chosen=$(printf '%s\n' "${!categories[@]}" | rofi -dmenu -i -p "Categorias")

# Se uma categoria foi escolhida, abre o Rofi filtrado
if [ -n "$chosen" ]; then
  # Fecha a instância do menu de categorias
  killall rofi 2>/dev/null
  sleep 0.1
  # Abre o Rofi com a categoria selecionada
  rofi -show drun -drun-categories "${categories[$chosen]}"
fi
