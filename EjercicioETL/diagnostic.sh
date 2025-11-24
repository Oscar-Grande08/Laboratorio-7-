#!/bin/bash
echo " Diagnóstico del Sistema"
echo "Directorio: $(pwd)"
echo "Python: $(python3 --version)"
echo "Estructura:"
find . -type f -name "*.sh" -o -name "*.py" -o -name "*.xlsx" | sort
echo "Permisos:"
ls -la *.sh 2>/dev/null
