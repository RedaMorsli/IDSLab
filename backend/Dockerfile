FROM python:3.11

# Copy Python app
COPY . /app
WORKDIR /app

# Install requirements
RUN pip install -r requirements.txt

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl


ENTRYPOINT ["python", "-u", "server.py"]