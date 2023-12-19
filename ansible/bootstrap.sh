#!/bin/bash

set -Eeuo pipefail

INVENTORY_NAME="default"
readonly INVENTORY_NAME

NET_PREFIX="10.28.28"
readonly NET_PREFIX

SSH_SMP_PORT="22"
readonly SSH_PORT

SSH_FNL_PORT="17543"
readonly FNL_PORT

main() {
  local -A ip_aliases
  
  while read -r ip; do
    local id; id=$(printf "%s" "${ip}" | awk -F'.' '{print $4}')
    ip_aliases["${id}-smp"]="cluster.${id}.smp"
    ip_aliases["${id}-fnl"]="cluster.${id}.fnl"
    printf "Host cluster.%s.smp\n  HostName %s\n  Port %s\n\n" "${id}" "${ip}" "${SSH_SMP_PORT}"
    printf "Host cluster.%s.fnl\n  HostName %s\n  Port %s\n\n" "${id}" "${ip}" "${SSH_FNL_PORT}"
  done < <(
    seq 10 245 | while read -r host; do
      ip="${NET_PREFIX}.${host}"
      {
        if ping -c 1 -W 1 "${ip}" > /dev/null 2>&1; then
          echo "${ip}"
        fi
      } &
    done
    wait
  ) > ssh_config

  printf "[default-smp]" > default.ini
  for alias in "${!ip_aliases[@]}"; do
    if [[ "${alias}" == *"-smp" ]]; then
      printf "\n%s" "${ip_aliases[$alias]}" >> default.ini
    fi
  done

  printf "\n\n[default-fnl]" >> default.ini
  for alias in "${!ip_aliases[@]}"; do
    if [[ "${alias}" == *"-fnl" ]]; then
      printf "\n%s" "${ip_aliases[$alias]}" >> default.ini
    fi
  done
}

main "${@}"
