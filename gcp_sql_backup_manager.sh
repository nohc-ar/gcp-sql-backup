#!/bin/bash

# Script: gcp_sql_backup_manager.sh
# Descripción: Descarga y encripta backups de Cloud SQL con configuración externa

# Cargar configuración desde archivo
CONFIG_FILE="/etc/gcp_backup.conf"

# Función para cargar configuración
load_config() {
    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "[$(date '+%F %T')] Error: Archivo de configuración no encontrado: ${CONFIG_FILE}" >&2
        exit 1
    fi

    # Validar permisos del archivo de configuración
    if [ $(stat -c %a "${CONFIG_FILE}") -gt 600 ]; then
        echo "[$(date '+%F %T')] Error: Permisos inseguros en ${CONFIG_FILE}" >&2
        exit 1
    fi

    source "${CONFIG_FILE}" || {
        echo "[$(date '+%F %T')] Error: Fallo al cargar configuración" >&2
        exit 1
    }

    # Validar variables esenciales
    local required_vars=("ENCRYPTION_PASSPHRASE" "GCS_BACKUP_BUCKET_PATH" "BACKUP_DIR")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "[$(date '+%F %T')] Error: Variable ${var} no configurada" >&2
            exit 1
        fi
    done
}

# Resto del script (las funciones anteriores modificadas)
# ---------------------------------------------------------------
LOG_FILE="/var/log/gcp_backup.log"
ENCRYPTION_SUFFIX=".aes256"

log_check_message() {
    local timestamp=$(date '+%a %b %e %T %Y')
    local log_message="[${timestamp}] $1"
    echo "${log_message}" >> "${LOG_FILE}" || {
        echo "[${timestamp}] [error] Error escribiendo en log: $1" | tee -a "${LOG_FILE}"
        exit 1
    }
}

check_dependencies() {
    local dependencies=("gsutil" "gpg")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            log_check_message "[critical] Comando requerido: ${cmd} no encontrado"
            exit 1
        fi
    done
    log_check_message "[info] Dependencias verificadas"
}

get_latest_backup() {
    log_check_message "[info] Buscando último backup en ${GCS_BACKUP_BUCKET_PATH}"
    
    local latest_backup_uri=$(gsutil ls -l "${GCS_BACKUP_BUCKET_PATH}" | grep -v "TOTAL:" | sort -k2 | tail -n1 | awk '{print $3}')
    
    if [ -z "${latest_backup_uri}" ]; then
        log_check_message "[error] No hay backups disponibles"
        exit 1
    fi
    
    BACKUP_FILE_NAME=$(basename "${latest_backup_uri}")
    LOCAL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE_NAME}"
    ENCRYPTED_FILE="${LOCAL_BACKUP_PATH}${ENCRYPTION_SUFFIX}"
    
    log_check_message "[info] Backup identificado: ${BACKUP_FILE_NAME}"
}

download_backup() {
    log_check_message "[info] Iniciando descarga a ${LOCAL_BACKUP_PATH}"
    
    if ! gsutil cp "${latest_backup_uri}" "${LOCAL_BACKUP_PATH}"; then
        log_check_message "[error] Fallo en descarga"
        exit 1
    fi
    
    log_check_message "[info] Descarga completada: $(ls -lh "${LOCAL_BACKUP_PATH}")"
}

encrypt_backup() {
    log_check_message "[info] Iniciando encriptación"
    
    if ! gpg --batch --yes \
        --passphrase "${ENCRYPTION_PASSPHRASE}" \
        --cipher-algo AES256 \
        --output "${ENCRYPTED_FILE}" \
        --symmetric "${LOCAL_BACKUP_PATH}"; then
        log_check_message "[error] Fallo en encriptación"
        exit 1
    fi
    
    log_check_message "[info] Encriptación completada: ${ENCRYPTED_FILE}"
    rm -f "${LOCAL_BACKUP_PATH}" && log_check_message "[info] Original eliminado"
}

main() {
    load_config  # Carga la configuración primero
    check_dependencies
    mkdir -p "${BACKUP_DIR}" || {
        log_check_message "[error] Fallo creando directorio"
        exit 1
    }
    
    get_latest_backup
    download_backup
    encrypt_backup
    
    log_check_message "[success] Proceso completado"
}

main
