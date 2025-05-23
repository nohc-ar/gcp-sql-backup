# GCP SQL Backup Manager

A secure bash script for downloading and encrypting Google Cloud SQL backups with external configuration management.

[English](#english-documentation) | [Español](#documentación-en-español)

---

## English Documentation

### Overview

The GCP SQL Backup Manager is a robust bash script designed to automate the process of downloading the latest Cloud SQL backup from Google Cloud Storage and encrypting it locally using AES256 encryption. The script features external configuration management, comprehensive logging, and security validations.


### Features

- **Automated Backup Retrieval**: Automatically identifies and downloads the latest backup from GCS
- **AES256 Encryption**: Secures backups with symmetric encryption using GPG
- **External Configuration**: Uses a separate configuration file for security and maintainability
- **Comprehensive Logging**: Detailed timestamped logs for monitoring and troubleshooting
- **Security Validations**: Verifies configuration file permissions and required dependencies
- **Error Handling**: Robust error handling with proper exit codes

### Diagram

```mermaid
graph TD
    A[Inicio] --> B[Exportar DB a GCS]
    B --> C[Descargar de GCS]
    C --> D{Encriptar?}
    D -->|Sí| E[Encriptar y eliminar original]
    D -->|No| F[Mantener backup original]
``

### Prerequisites

- **Google Cloud SDK**: `gsutil` command must be installed and configured
- **GPG**: GNU Privacy Guard for encryption operations
- **Bash**: Version 4.0 or higher
- **Appropriate GCS permissions**: Read access to the backup bucket

### Installation

1. **Download the script**:
   ```bash
   git clone https://your-repo.com/gcp_sql_backup_manager.sh
   chmod +x gcp_sql_backup_manager.sh
   ```

2. **Create the configuration file**:
   ```bash
   sudo touch /etc/gcp_backup.conf
   sudo chmod 600 /etc/gcp_backup.conf
   ```

3. **Configure the script** (edit `/etc/gcp_backup.conf`):
   ```bash
   # Encryption passphrase (keep secure!)
   ENCRYPTION_PASSPHRASE="your-strong-passphrase-here"
   
   # GCS bucket path where backups are stored
   GCS_BACKUP_BUCKET_PATH="gs://your-bucket/path/to/backups/"
   
   # Local directory for temporary backup storage
   BACKUP_DIR="/opt/backups"
   ```

### Usage

#### Basic Usage
```bash
sudo ./gcp_sql_backup_manager.sh
```

#### Automated Execution with Cron
```bash
# Add to crontab for daily execution at 2 AM
0 2 * * * /path/to/gcp_sql_backup_manager.sh >> /var/log/cron_backup.log 2>&1
```

### Configuration File

The script requires a configuration file at `/etc/gcp_backup.conf` with the following variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `ENCRYPTION_PASSPHRASE` | Passphrase for AES256 encryption | `"MySecurePassphrase123!"` |
| `GCS_BACKUP_BUCKET_PATH` | GCS path to backup location | `"gs://my-backups/sql/"` |
| `BACKUP_DIR` | Local directory for backup storage | `"/opt/backups"` |

**Security Note**: The configuration file must have permissions `600` (read/write for owner only).

### Logging

The script generates detailed logs at `/var/log/gcp_backup.log` with the following format:
```
[Mon Jan 15 14:30:25 2024] [info] Dependencias verificadas
[Mon Jan 15 14:30:26 2024] [info] Backup identificado: backup_20240115.sql
[Mon Jan 15 14:30:45 2024] [success] Proceso completado
```

### Error Handling

The script includes comprehensive error handling for:
- Missing dependencies
- Configuration file issues
- Permission problems
- Network failures during download
- Encryption failures

### Security Features

- **Configuration file permission validation**: Ensures secure file permissions
- **Encrypted storage**: All backups are encrypted with AES256
- **Secure cleanup**: Original unencrypted files are automatically removed
- **Comprehensive logging**: Full audit trail of operations

---

## Documentación en Español

### Descripción General

El GCP SQL Backup Manager es un script robusto de bash diseñado para automatizar el proceso de descarga del último backup de Cloud SQL desde Google Cloud Storage y encriptarlo localmente usando encriptación AES256. El script incluye gestión de configuración externa, logging comprehensivo y validaciones de seguridad.

### Características

- **Recuperación Automática de Backups**: Identifica y descarga automáticamente el último backup desde GCS
- **Encriptación AES256**: Asegura los backups con encriptación simétrica usando GPG
- **Configuración Externa**: Usa un archivo de configuración separado para seguridad y mantenibilidad
- **Logging Comprehensivo**: Logs detallados con marcas de tiempo para monitoreo y resolución de problemas
- **Validaciones de Seguridad**: Verifica permisos del archivo de configuración y dependencias requeridas
- **Manejo de Errores**: Manejo robusto de errores con códigos de salida apropiados

### Prerrequisitos

- **Google Cloud SDK**: El comando `gsutil` debe estar instalado y configurado
- **GPG**: GNU Privacy Guard para operaciones de encriptación
- **Bash**: Versión 4.0 o superior
- **Permisos apropiados en GCS**: Acceso de lectura al bucket de backups

### Instalación

1. **Descargar el script**:
   ```bash
   git clone https://tu-repo.com/gcp_sql_backup_manager.sh
   chmod +x gcp_sql_backup_manager.sh
   ```

2. **Crear el archivo de configuración**:
   ```bash
   sudo touch /etc/gcp_backup.conf
   sudo chmod 600 /etc/gcp_backup.conf
   ```

3. **Configurar el script** (editar `/etc/gcp_backup.conf`):
   ```bash
   # Frase de contraseña para encriptación (¡mantener segura!)
   ENCRYPTION_PASSPHRASE="tu-frase-segura-aqui"
   
   # Ruta del bucket GCS donde se almacenan los backups
   GCS_BACKUP_BUCKET_PATH="gs://tu-bucket/ruta/a/backups/"
   
   # Directorio local para almacenamiento temporal de backups
   BACKUP_DIR="/opt/backups"
   ```

### Uso

#### Uso Básico
```bash
sudo ./gcp_sql_backup_manager.sh
```

#### Ejecución Automatizada con Cron
```bash
# Agregar a crontab para ejecución diaria a las 2 AM
0 2 * * * /ruta/al/gcp_sql_backup_manager.sh >> /var/log/cron_backup.log 2>&1
```

### Archivo de Configuración

El script requiere un archivo de configuración en `/etc/gcp_backup.conf` con las siguientes variables:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `ENCRYPTION_PASSPHRASE` | Frase de contraseña para encriptación AES256 | `"MiFraseSegura123!"` |
| `GCS_BACKUP_BUCKET_PATH` | Ruta GCS a la ubicación de backups | `"gs://mis-backups/sql/"` |
| `BACKUP_DIR` | Directorio local para almacenamiento de backups | `"/opt/backups"` |

**Nota de Seguridad**: El archivo de configuración debe tener permisos `600` (lectura/escritura solo para el propietario).

### Logging

El script genera logs detallados en `/var/log/gcp_backup.log` con el siguiente formato:
```
[Mon Jan 15 14:30:25 2024] [info] Dependencias verificadas
[Mon Jan 15 14:30:26 2024] [info] Backup identificado: backup_20240115.sql
[Mon Jan 15 14:30:45 2024] [success] Proceso completado
```

### Manejo de Errores

El script incluye manejo comprehensivo de errores para:
- Dependencias faltantes
- Problemas con el archivo de configuración
- Problemas de permisos
- Fallos de red durante la descarga
- Fallos de encriptación

### Características de Seguridad

- **Validación de permisos del archivo de configuración**: Asegura permisos seguros de archivo
- **Almacenamiento encriptado**: Todos los backups son encriptados con AES256
- **Limpieza segura**: Los archivos originales no encriptados se eliminan automáticamente
- **Logging comprehensivo**: Rastro completo de auditoría de operaciones
