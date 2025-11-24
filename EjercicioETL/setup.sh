echo "Instalando dependencias..."
sudo apt update
sudo apt install -y python3 python3-pip sqlite3
pip3 install pandas streamlit openpyxl plotly numpy
echo " Dependencias instaladas"
