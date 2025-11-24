#!/usr/bin/env python3
import streamlit as st
import pandas as pd
import sqlite3
import plotly.express as px

st.set_page_config(page_title="Dashboard Sensores", layout="wide")
st.title(" Dashboard de Sensores")

@st.cache_data
def load_data():
    conn = sqlite3.connect('database/sensors.db')
    sensor_data = pd.read_sql('SELECT * FROM sensor_measurements', conn)
    sensor_summary = pd.read_sql('SELECT * FROM sensor_summary', conn)
    conn.close()
    return sensor_data, sensor_summary

def main():
    sensor_data, sensor_summary = load_data()
    
    st.sidebar.title("Filtros")
    selected_sheet = st.sidebar.selectbox("Tipo de Sensor:", sensor_data['sheet_name'].unique())
    
    # Métricas
    col1, col2, col3, col4 = st.columns(4)
    with col1: st.metric("Total Mediciones", len(sensor_data))
    with col2: st.metric("Sensores", len(sensor_summary))
    with col3: st.metric("Voltaje Promedio", f"{sensor_summary['average_value'].mean():.2f}V")
    with col4: st.metric("Valor Máximo", f"{sensor_summary['max_value'].max():.2f}V")
    
    # Pestañas
    tab1, tab2, tab3 = st.tabs(["Resumen", "Gráficos", "Datos"])
    
    with tab1:
        st.subheader("Resumen por Sensor")
        st.dataframe(sensor_summary.style.format({
            'average_value': '{:.3f}',
            'min_value': '{:.3f}', 
            'max_value': '{:.3f}',
            'std_dev': '{:.3f}'
        }))
    
    with tab2:
        st.subheader("Distribución de Voltajes")
        fig = px.box(sensor_summary, y='average_value', title='Distribución de Valores Promedio')
        st.plotly_chart(fig, use_container_width=True)
        
        # Gráfico de barras
        fig_bar = px.bar(sensor_summary.head(20), x='sensor_id', y='average_value',
                        title='Top 20 Sensores - Valores Promedio')
        st.plotly_chart(fig_bar, use_container_width=True)
    
    with tab3:
        st.subheader("Datos Completos")
        filtered_data = sensor_data[sensor_data['sheet_name'] == selected_sheet]
        st.dataframe(filtered_data, use_container_width=True)

if __name__ == "__main__":
    main()
