# Používáme 64-bitový základní obraz pro Raspberry Pi
FROM arm64v8/ubuntu:latest

# Nastavíme pracovní adresář
WORKDIR /usr/src/app

# Nainstalujeme potřebné balíčky (např. bash pro skripty)
RUN apt-get update && apt-get install -y \
    bash \
    tcpdump \
    docker.io \
    coreutils

# Instalace Docker CLI
RUN apt-get install -y docker.io

# Zkopírujeme skript do kontejneru
COPY monitor.sh .

# Uděláme skript spustitelným
RUN chmod +x monitor.sh

# Spustíme skript při startu kontejneru
CMD ["./monitor.sh"]
