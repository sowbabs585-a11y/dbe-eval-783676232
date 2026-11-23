
#!/bin/bash

while true; do
    trap 'echo "$(date) arrêt propre" >> logs/surveillance.log; exit 0' TERM

    echo "$(date '+%F %T') - Nombre de lignes : $(wc -l < logs/access.log)" >> logs/surveillance.log

    sleep 5 &
    wait $!
done
