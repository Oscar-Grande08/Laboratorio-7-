#imagen base de Python
FROM python:3.10

#instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

#crear directorio de trabajo
WORKDIR /app

#copiar archivos del proyecto
COPY requerimientos.txt .
COPY Sentimientos.py .

#instalar dependencias Python
RUN pip install --no-cache-dir -r requerimientos.txt

#exponer el puerto de Streamlit
EXPOSE 8501

#comando de inicio
CMD ["streamlit", "run", "Sentimientos.py", "--server.port=8501", "--server.address=0.0.0.0"]
