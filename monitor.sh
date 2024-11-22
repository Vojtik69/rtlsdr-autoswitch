#!/bin/bash

# Definice IP adresy Raspberry Pi
MY_IP="${MY_IP:-192.168.8.152}"  # Změňte na svou skutečnou IP adresu
PORT="${PORT:-1234}"
IDLE_TIME="${IDLE_TIME:-60}"
INTERFACE="${INTERFACE}"

# Funkce pro spuštění nebo zastavení kontejnerů
start_rtlsdr() {
    echo "Spouštím rtlsdr_tcp..."
    docker start rtlsdr_tcp
}

stop_rtlsdr() {
    echo "Zastavuji rtlsdr_tcp..."
    docker stop rtlsdr_tcp
}

start_ultrafeeder() {
    echo "Spouštím ultrafeeder..."
    docker restart ultrafeeder
}

stop_ultrafeeder() {
    echo "Zastavuji ultrafeeder..."
    docker stop ultrafeeder
}

# Funkce pro kontrolu, zda kontejner běží
is_rtlsdr_running() {
    # Získáme ID kontejneru, pokud je běžící
    container_id=$(docker ps --filter "name=rtlsdr_tcp" --filter "status=running" -q)
    echo "$container_id"
    # Pokud je container_id prázdné, znamená to, že kontejner neběží
    if [ -n "$container_id" ]; then
        #echo "rtlsdr bezi "
        return 0  # Kontejner běží
    else
        #echo "rtlsdr nebezi"
        return 1  # Kontejner neběží
    fi
}

echo "Zacinam sledovat"

# Monitorování pomocí tcpdump
while true; do
    # Sledujeme příchozí TCP pakety na portu 1234, pouze z externího zařízení
    tcpdump -i ${INTERFACE} port $PORT and src not $MY_IP -c 1 > /dev/null 2>&1
    echo "Doslo k pozadavku na portu $PORT"
    # Pokud rtlsdr_tcp není běžící a dojde k TCP požadavku, zastavíme ultrafeeder a spustíme rtlsdr_tcp
    if ! is_rtlsdr_running; then
        echo "rtlsdr_tcp nebezel, jdu ho zapnout"
        stop_ultrafeeder
        start_rtlsdr
    else
        echo "rtlsdr_tcp uz bezi"
    fi

    start_time=$(date +%s)

    while true; do
      # Pozadavek behem vteriny?
      OUTPUT=$(timeout 1 tcpdump -i ${INTERFACE} port $PORT and src not $MY_IP -c 1 2>&1)
      #echo "$OUTPUT"
      if echo "$OUTPUT" | grep -q "^0 packets received"; then
          end=$(date +%s)
          elapsed=$((end - start_time))
          echo "timeout: $elapsed s"
          if [ $elapsed -ge $IDLE_TIME ] && is_rtlsdr_running; then
              echo "timeout>$IDLE_TIME, jdu rtlsdr vypnout"
              stop_rtlsdr
              start_ultrafeeder
              break
          fi
      else
          start_time=$(date +%s)
      fi
      sleep 5
    done
done
