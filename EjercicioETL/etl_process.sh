# Configuración
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_FILE="$BASE_DIR/BD_SENSORES.xlsx"
PROCESSED_DIR="$BASE_DIR/data/processed"
LOG_DIR="$BASE_DIR/logs"
DB_FILE="$BASE_DIR/database/sensors.db"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Crear directorios
mkdir -p "$PROCESSED_DIR" "$LOG_DIR" "$(dirname "$DB_FILE")"
LOG_FILE="$LOG_DIR/etl_$(date +%Y%m%d_%H%M%S).log"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Inicio
log "Iniciando ETL"
log "Directorio: $BASE_DIR"

# Verificar archivo Excel
if [ ! -f "$INPUT_FILE" ]; then
    log "ERROR: No se encuentra $INPUT_FILE"
    exit 1
fi

# Crear script Python si no existe
if [ ! -f "$SCRIPTS_DIR/process_sensors.py" ]; then
    log "Creando script Python..."
    cat > "$SCRIPTS_DIR/process_sensors.py" << 'EOF'
import pandas as pd
import sqlite3
import sys
from datetime import datetime
import os

def log_message(message):
    print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}")

def process_sensor_data(input_file):
    sheets = ['SENP1', 'SENP2', 'SENP3', 'SENP4', 'SENP5', 'SEN_V', 'SEN_SP1', 'SEN_SP2', 'SEN_GAR1', 'SEN_GAR2', 'SEN_PUL1', 'SEN_PUL2', 'SEN_ANTI', 'SEN_SPI1', 'SEN_SPI2', 'SEN_MAR', 'EMG']
    all_data = []
    
    for sheet_name in sheets:
        try:
            log_message(f"Procesando {sheet_name}")
            df = pd.read_excel(input_file, sheet_name=sheet_name, header=2)
            df.columns = [f'sensor_{i+1}' for i in range(len(df.columns))]
            df = df.dropna(how='all')
            
            for col in df.columns:
                if df[col].dtype == 'object':
                    df[col] = pd.to_numeric(
                        df[col].astype(str).str.replace(' V', '', regex=False), 
                        errors='coerce'
                    )
            
            df['sheet_name'] = sheet_name
            df['timestamp'] = datetime.now()
            df['measurement_id'] = range(len(df))
            all_data.append(df)
            
        except Exception as e:
            log_message(f"Error en {sheet_name}: {str(e)}")
            continue
    
    if all_data:
        return pd.concat(all_data, ignore_index=True)
    return None

def create_database(df, db_file):
    try:
        conn = sqlite3.connect(db_file)
        df.to_sql('sensor_measurements', conn, if_exists='replace', index=False)
        
        # Resumen por sensor
        summary_data = []
        sensor_cols = [col for col in df.columns if col.startswith('sensor_')]
        for col in sensor_cols:
            sensor_data = df[col].dropna()
            if len(sensor_data) > 0:
                summary_data.append({
                    'sensor_id': col,
                    'average_value': sensor_data.mean(),
                    'min_value': sensor_data.min(),
                    'max_value': sensor_data.max(),
                    'std_dev': sensor_data.std()
                })
        
        pd.DataFrame(summary_data).to_sql('sensor_summary', conn, if_exists='replace', index=False)
        conn.close()
        return True
        
    except Exception as e:
        log_message(f"Error BD: {str(e)}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python process_sensors.py <input_file> <db_file>")
        sys.exit(1)
        
    input_file, db_file = sys.argv[1], sys.argv[2]
    
    if not os.path.exists(input_file):
        log_message(f"Archivo no existe: {input_file}")
        sys.exit(1)
    
    processed_data = process_sensor_data(input_file)
    if processed_data is not None:
        if create_database(processed_data, db_file):
            log_message("Procesamiento exitoso")
        else:
            log_message("Error creando BD")
    else:
        log_message("Error procesando datos")
EOF
fi

# Ejecutar procesamiento
log "Ejecutando procesamiento Python..."
python3 "$SCRIPTS_DIR/process_sensors.py" "$INPUT_FILE" "$DB_FILE"

if [ -f "$DB_FILE" ]; then
    log " ETL completado - BD creada: $DB_FILE"
    # Mostrar resumen
    sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sensor_measurements;" | tee -a "$LOG_FILE"
    sqlite3 "$DB_FILE" "SELECT sheet_name, COUNT(*) FROM sensor_measurements GROUP BY sheet_name;" | tee -a "$LOG_FILE"
else
    log " ETL falló"
    exit 1
fi
