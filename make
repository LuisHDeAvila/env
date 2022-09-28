#!/bin/sh
: '
  author: eleAche
  script para configuracion de entorno Linux
  from: https://github.com/luishdeavila/env
  Entornos objetivo: ArchLinux base, Termux (root y no-root), 

'
# obtener version del sistema
function readsystem(){ uname -a | awk '{print $3}' ; } 

function confirmar_antes(){ read -p "ok, tu sistema es $1, para configurar el entorno presiona [ENTER], para abortar la configuracion presiona [CTRL]+C " confirmacion  ; }

# Deteccion automatica del entorno.
case `readsystem | grep -Eo '[a-zA-Z]+'` in 
arch )
  confirmar_antes ArchLinux && ./Arch/install ;;
termux )
  confirmar_antes Termux && ./Termux/install ;;
esac
