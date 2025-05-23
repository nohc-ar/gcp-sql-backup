#!/bin/bash

# Script: gcp_sql_backup_manager.sh
# Descripción: Exporta, descarga y encripta backups de Cloud SQL

# Configuración
CONFIG_FILE="/etc/gcp_backup.conf"
LOG_FILE="/var/log/gcp_backup.log"
ENCRYPTION_SUFFIX=".aes256"

# Cargar configuración
load_config() {
    if [ ! -f "${CONFIG_FILE}" ]; then
        log "error" "Archivo de configuración no encontrado"
        exit 1
    fi

    source "${CONFIG_FILE}" || {
        log "error" "Fallo al cargar configuración"
        exit 1
    }

    required_vars=(
        "CLOUD_SQL_INSTANCE"
        "GCS_EXPORT_BUCKET"
        "BACKUP_DIR"
    )
    for var in "${required_vars[@]}"; do
        [ -z "${!var}" ] && {
            log "error" "Variable $var no configurada"
            exit 1
        }
    done

    EXCLUDE_DATABASES="${EXCLUDE_DATABASES:-"information_schema mysql sys performance_schema"}"
    BACKUP_TIMEOUT="${BACKUP_TIMEOUT:-3600}"
}

# Logger con niveles
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%F %T')] [${level}] ${message}" >> "$LOG_FILE"
    # Opcional: Mostrar en consola también
    echo "[$(date '+%F %T')] [${level}] ${message}" >&2
}



# Exportar base de datos a GCS
export_database() {
    local db_name="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local gcs_uri="gs://${GCS_EXPORT_BUCKET}/${db_name}/${db_name}_${timestamp}.gz"
    
    log "info" "DB: $db_name - Iniciando exportación a: $gcs_uri"
    
    if ! gcloud sql export bak "${CLOUD_SQL_INSTANCE}" "${gcs_uri}" \
        --database="${db_name}" \
        --quiet >/dev/null 2>&1; then
        log "error" "DB: $db_name - Falló la exportación"
        return 1
    fi
    
    echo "$gcs_uri"  # Devolver URI del backup
}

# Descargar y procesar backup
process_backup() {
    local db_name="$1"
    local gcs_uri="$2"
    local backup_file=$(basename "$gcs_uri")
    local local_path="${BACKUP_DIR}/${db_name}/${backup_file}"
    
    # Descargar de GCS
    log "info" "DB: $db_name - Descargando backup..."
    mkdir -p "$(dirname "$local_path")"
    if ! gsutil cp "$gcs_uri" "$local_path"; then
        log "error" "DB: $db_name - Falló la descarga"
        return 1
    fi

    # Encriptación opcional
    if [ -n "$ENCRYPTION_PASSPHRASE" ]; then
        log "info" "DB: $db_name - Encriptando..."
        if ! gpg --batch --yes \
            --passphrase "$ENCRYPTION_PASSPHRASE" \
            --cipher-algo AES256 \
            --output "${local_path}${ENCRYPTION_SUFFIX}" \
            --symmetric "$local_path"; then
            log "error" "DB: $db_name - Falló la encriptación"
            return 1
        fi
        rm -f "$local_path"
        log "info" "DB: $db_name - Backup encriptado: ${backup_file}${ENCRYPTION_SUFFIX}"
    else
        log "info" "DB: $db_name - Backup descargado: $local_path"
    fi
}

main() {
    load_config
    log "info" "=== Iniciando proceso completo de backup ==="
    
    # Obtener listado de bases de datos
    databases=$(gcloud sql databases list --instance="$CLOUD_SQL_INSTANCE" --format="value(name)")
    
    echo "$databases" | while read -r db; do
        if [[ " $EXCLUDE_DATABASES " == *" $db "* ]]; then
            log "info" "DB: $db - Excluida de procesamiento"
            continue
        fi
        
        log "info" "DB: $db - Procesando..."
        
        # Paso 1: Exportar a GCS
        if gcs_uri=$(export_database "$db"); then
            # Paso 2: Descargar y encriptar
            log "debug" "URI obtenida: $gcs_uri"  # Formato correcto
            process_backup "$db" "$gcs_uri"
        fi
        
        log "info" "DB: $db - Proceso completado"
    done
    
    log "info" "=== Proceso finalizado ==="
}

main
