FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
RUN pip install --no-cache-dir pymodbus==3.5.4 paho-mqtt==2.1.0 pyserial==3.5
WORKDIR /app
COPY main.py /app/main.py
CMD ["python", "-u", "main.py"]
