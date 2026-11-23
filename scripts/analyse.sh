
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage : bash scripts/analyse.sh <fichier.log> [--top N]" >&2
}

verifier_fichier() {
    if [[ ! -f "$1" ]]; then
        echo "Erreur : fichier inexistant" >&2
        exit 2
    fi
    if [[ ! -s "$1" ]]; then
        echo "Erreur : fichier vide" >&2
        exit 3
    fi
}

compter_famille() {
    awk -v famille="$1" '$9 ~ ("^" famille) {n++} END {print n+0}' "$fichier"
}

top_endpoints() {
    awk '{print $7}' "$fichier" |
    sed 's/?page=.*//' |
    sort | uniq -c | sort -rn | head -n "$top"
}

ip_suspecte() {
    awk '$9==401 && $7=="/api/auth/login" {print $1}' "$fichier" |
    sort | uniq -c | sort -rn | head -n 1
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
    usage
    exit 1
fi

if [[ -z "${MATRICULE:-}" ]]; then
    echo "Erreur : MATRICULE non définie" >&2
    exit 1
fi

fichier="$1"
top=3

if [[ $# -eq 2 ]]; then
    usage
    exit 1
fi

if [[ $# -eq 3 ]]; then
    if [[ "$2" != "--top" || ! "$3" =~ ^[1-9][0-9]*$ ]]; then
        usage
        exit 1
    fi
    top="$3"
fi

verifier_fichier "$fichier"

mkdir -p rapports

date_rapport=$(date +%Y%m%d_%H%M)
rapport="rapports/rapport_${MATRICULE}_${date_rapport}.txt"

{
    echo "RAPPORT D'ANALYSE"
    echo "Date : $(date)"
    echo "Utilisateur@machine : $(whoami)@$(hostname)"
    echo "Matricule : $MATRICULE"
    echo
    echo "SHA256 :"
    sha256sum "$fichier"
    echo
    echo "REQUETES PAR FAMILLE HTTP"
    for famille in 2 3 4 5; do
        echo "${famille}xx : $(compter_famille "$famille")"
    done
    echo
    echo "TOP $top ENDPOINTS"
    top_endpoints
    echo
    echo "IP SUSPECTE"
    ip_suspecte
    echo
    echo "TEMPS MOYEN DES REQUETES 200"
    awk '$9==200 {s+=$(NF); n++} END {if(n) printf "%.1f ms\n",s/n; else print "Aucune"}' "$fichier"
} > "$rapport"

echo "Rapport créé : $rapport"
