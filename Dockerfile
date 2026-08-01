# FALLA CONTENEDOR 1: Imagen base antigua con múltiples CVEs
FROM python:3.7-slim
WORKDIR /app
COPY app/ /app/
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8080
# FALLA CONTENEDOR 2: Se ejecuta como usuario root
CMD ["python", "app.py"]
