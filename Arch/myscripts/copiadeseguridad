#!/usr/bin/env bash
: '
  title: file system enum
  author: eleAche
  description: crea una enumeracion de archivos, cada 10 minutos.



'
# color suport
red_="\e[1;31m\033[1m"
green_="\e[0;32m\033[1m"
blue_="\e[0;34m\033[1m"
yellow_="\e[0;33m\033[1m"
purple_="\e[0;35m\033[1m"
turquesa_="\e[0;36m\033[1m"
gray_="\e[0;37m\033[1m"
_end="\033[0m\e[0m"

# input
echo -e $gray_
cat <<INICIO
  ejemplo de ruta absoluta: /home/user/tarea/historia
  ejemplo de ruta relativa: ./historia
INICIO
read -p " Ruta absoluta del directorio a copiar: " DIRECTORIO_ORIGEN
read -p " Ruta absoluta del directorio de copias de seguridad: " DIRECTORIO_DESTINO
echo -e $_end

# main
function CopiasDeSeguridad() {
  FECHA=$(date +%Y.%m.%d-%H.%M.%S)

  function CopiaTotal() {

    RUTA_FICHEROS=$DIRECTORIO_DESTINO
    FICHERO_ULTIMA_COPIA_TOTAL=$RUTA_FICHEROS/fecha-ultima-copia-total.txt
    FICHERO_COMPRIMIDO=$RUTA_FICHEROS/total-$FECHA.tar.zip
    DIRECTORIO_A_COPIAR=$DIRECTORIO_ORIGEN
    if [ ! -d $DIRECTORIO_A_COPIAR ]; then
      echo "No existe el directorio a copiar."
      exit 1
    fi
    if [ ! -d $RUTA_FICHEROS ]; then
      mkdir $RUTA_FICHEROS
    fi
    echo $FECHA >$FICHERO_ULTIMA_COPIA_TOTAL
    zip -r $FICHERO_COMPRIMIDO $DIRECTORIO_A_COPIAR
  }

  function CopiaDiferencial() {
    RUTA_FICHEROS=$DIRECTORIO_DESTINO
    FICHERO_ULTIMA_COPIA_TOTAL=$RUTA_FICHEROS/fecha-ultima-copia-total.txt
    FICHERO_ULTIMA_COPIA_DIFERENCIAL=$RUTA_FICHEROS/fecha-ultima-copia-diferencial.txt
    FICHERO_COMPRIMIDO=$RUTA_FICHEROS/diferencial-$FECHA.tar.zip
    DIRECTORIO_A_COPIAR=$DIRECTORIO_ORIGEN
    if [ ! -d $DIRECTORIO_A_COPIAR ]; then
      echo "No existe el directorio a copiar."
      exit 1
    fi
    if [ ! -e $FICHERO_ULTIMA_COPIA_TOTAL ]; then
      echo "No hay última copia total."
      exit 1
    fi
    if [ ! -d $RUTA_FICHEROS ]; then
      mkdir $RUTA_FICHEROS
    fi
    echo $FECHA >$FICHERO_ULTIMA_COPIA_DIFERENCIAL
    find $DIRECTORIO_A_COPIAR/* -newer $FICHERO_ULTIMA_COPIA_TOTAL | zip -@ $FICHERO_COMPRIMIDO
  }

  function CopiaIncremental() {
    RUTA_FICHEROS=$DIRECTORIO_DESTINO
    FICHERO_ULTIMA_COPIA_TOTAL=$RUTA_FICHEROS/fecha-ultima-copia-total.txt
    FICHERO_ULTIMA_COPIA_DIFERENCIAL=$RUTA_FICHEROS/fecha-ultima-copia-diferencial.txt
    FICHERO_ULTIMA_COPIA_INCREMENTAL=$RUTA_FICHEROS/fecha-ultima-copia-incremental.txt
    FICHERO_COMPRIMIDO=$RUTA_FICHEROS/diferencial-$FECHA.tar.zip
    DIRECTORIO_A_COPIAR=$DIRECTORIO_ORIGEN
    function copia_desde_ultima_incremental() {
      find $DIRECTORIO_A_COPIAR/*.txt -newer $FICHERO_ULTIMA_INCREMENTAL | zip -@ $FICHERO_COMPRIMIDO
      echo $FECHA >$FICHERO_ULTIMA_COPIA_INCREMENTAL
      exit 0
    }
    function copia_desde_ultima_diferencial() {
      echo $FECHA >$FICHERO_ULTIMA_COPIA_INCREMENTAL
      find $DIRECTORIO_A_COPIAR/*.txt -newer $FICHERO_ULTIMA_DIFERENCIAL | zip -@ $FICHERO_COMPRIMIDO
      exit 0
    }
    function copia_desde_ultima_total() {
      echo $FECHA >$FICHERO_ULTIMA_COPIA_INCREMENTAL
      find $DIRECTORIO_A_COPIAR/*.txt -newer $FICHERO_ULTIMA_COPIA | zip -@ $FICHERO_COMPRIMIDO
      exit 0
    }
    if [ ! -d $DIRECTORIO_A_COPIAR ]; then
      echo "No exixte el directorio a copiar."
      exit 1
    fi
    if [ ! -e $FICHERO_ULTIMA_COPIA_TOTAL ]; then
      echo "No hay última copia total."
      exit 1
    fi
    if [ ! -e $FICHERO_ULTIMA_COPIA_INCREMENTAL ]; then
      copia_desde_ultima_total
    fi
  }

  # ORDEN DE EJECUCION
  CopiaTotal
  CopiaDiferencial
  CopiaIncremental
}

CopiasDeSeguridad
