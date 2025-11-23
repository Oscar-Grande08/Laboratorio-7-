import streamlit as st
import cv2
import mediapipe as mp
import threading
import queue
import time
import math


# ============================================================
# 1. DETECTOR DE EMOCIONES (Mediapipe FaceMesh)
# ============================================================

mp_face = mp.solutions.face_mesh

def dist(a, b):
    return math.sqrt((a.x - b.x)**2 + (a.y - b.y)**2)

def detectar_emocion(frame):
    """Procesa un frame y retorna la emoción detectada."""

    with mp_face.FaceMesh(
        static_image_mode=False,
        max_num_faces=1,
        refine_landmarks=True,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    ) as face:

        results = face.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

        if not results.multi_face_landmarks:
            return "No detectada"

        landmarks = results.multi_face_landmarks[0].landmark

        boca_arriba = landmarks[13]
        boca_abajo = landmarks[14]
        apertura_boca = dist(boca_arriba, boca_abajo)

        ceja_izq_int = landmarks[70]
        ceja_der_int = landmarks[300]
        cejas_juntas = dist(ceja_izq_int, ceja_der_int)

        comisura_izq = landmarks[61]
        comisura_der = landmarks[291]
        curva_boca = comisura_der.y - comisura_izq.y

        # Reglas simples
        if apertura_boca > 0.025 and curva_boca < 0.01:
            return "Feliz"

        if cejas_juntas < 0.3:
            return "Enojado"

        if curva_boca > 0.0001: 
            return "Triste"

        return "Neutral"



# ============================================================
# 2. SISTEMA DE LOGS (hilo + mutex)
# ============================================================

mutex = threading.Lock()
emociones_q = queue.Queue(maxsize=5)

def log_emocion(emocion):
    """Escribe la emoción en el archivo logs.txt con protección mutex."""
    with mutex:
        with open("logs.txt", "a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} -> {emocion}\n")

def hilo_logger():
    """Hilo que consume emociones de la cola y las registra."""
    while True:
        emocion = emociones_q.get()
        log_emocion(emocion)



# ============================================================
# 3. INTERFAZ STREAMLIT Y CÁMARA
# ============================================================

# Iniciar el hilo logger
threading.Thread(target=hilo_logger, daemon=True).start()

st.title("Análisis de Sentimientos")
st.write("Detección de emociones (Feliz, Enojado, Triste)")


iniciar = st.checkbox("Iniciar cámara")
FRAME_WINDOW = st.image([])

cap = cv2.VideoCapture(0)


if iniciar:
    while True:
        ret, frame = cap.read()
        if not ret:
            st.write("Error al acceder a la cámara.")
            break

        emocion = detectar_emocion(frame)

        # Enviar al hilo logger
        try:
            emociones_q.put_nowait(emocion)
        except queue.Full:
            pass

        # Mostrar en pantalla
        cv2.putText(frame, emocion, (30, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        FRAME_WINDOW.image(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

else:
    cap.release()
