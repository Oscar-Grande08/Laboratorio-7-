#!/bin/bash
# run_project.sh

echo " Iniciando Proyecto de Dashboard de Sensores"

# Configurar la ruta base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "Directorio del proyecto: $PROJECT_DIR"

# Verificar que el archivo Excel existe
EXCEL_FILE="BD_SENSORES.xlsx"

if [ ! -f "$EXCEL_FILE" ]; then
    echo " ERROR: Archivo $EXCEL_FILE no encontrado en: $PROJECT_DIR"
    echo ""
    echo "Archivos presentes:"
    ls -la
    echo ""
    echo "Por favor, coloca el archivo $EXCEL_FILE en este directorio"
    exit 1
fi

echo "✅ Archivo Excel encontrado"

# Crear estructura de directorios
mkdir -p data/raw data/processed scripts logs database

# Dar permisos
chmod +x etl_process.sh

# Ejecutar ETL
echo " Ejecutando proceso ETL..."
./etl_process.sh

if [ $? -eq 0 ]; then
    echo " ETL completado exitosamente"
    echo " Iniciando Dashboard Streamlit..."
    echo " Disponible en: http://localhost:8501"
    streamlit run dashboard.py
else
    echo " Error en el proceso ETL"
    exit 1
fi
