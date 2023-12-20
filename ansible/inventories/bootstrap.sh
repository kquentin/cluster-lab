#!/bin/bash

set -Eeuo pipefail

INVENTORY_NAME="default"
readonly INVENTORY_NAME

NET_PREFIX="10.28.28"
readonly NET_PREFIX

SSH_FACTORY_PORT="22"
readonly SSH_FACTORY_PORT

SSH_STOCKED_PORT="17852"
readonly SSH_STOCKED_PORT

main() {
  local -A ip_aliases
  
  while read -r alias; do
    local id; id=$(printf "%s" "${alias}" | awk -F '.' '{print $4}' | cut -d ":" -f 1)
    local ip; ip=$(echo ${alias} | cut -d ":" -f 1)
    local port; port=$(echo ${alias} | cut -d ":" -f 2)
    if [[ "${port}" = "${SSH_FACTORY_PORT}" ]]; then
      ip_aliases["${id}-factory"]="ansible_host=${ip} ansible_port=${SSH_FACTORY_PORT}"
    elif [[ "${port}" = "${SSH_STOCKED_PORT}" ]]; then
      ip_aliases["${id}-stocked"]="ansible_host=${ip} ansible_port=${SSH_STOCKED_PORT}"
    fi
  done < <(
    seq 10 245 | while read -r host; do
      ip="${NET_PREFIX}.${host}"
      {
        if nc -z -w 1  "${ip}" "${SSH_FACTORY_PORT}" > /dev/null 2>&1; then
          echo "${ip}:${SSH_FACTORY_PORT}"
        elif nc -z -w 1 "${ip}" "${SSH_STOCKED_PORT}" > /dev/null 2>&1; then
          echo "${ip}:${SSH_STOCKED_PORT}"
        fi
      } &
    done
    wait
  )

  printf "[factory_servers]" > "${INVENTORY_NAME}.ini"
  for alias in "${!ip_aliases[@]}"; do
    if [[ "${alias}" == *"-factory" ]]; then
      printf "\n%s %s" "${alias}" "${ip_aliases[$alias]}" >> "${INVENTORY_NAME}.ini"
    fi
  done

  printf "\n\n[stocked_servers]" >> "${INVENTORY_NAME}.ini"
  for alias in "${!ip_aliases[@]}"; do
    if [[ "${alias}" == *"-stocked" ]]; then
      printf "\n%s %s" "${alias}" "${ip_aliases[$alias]}" >> "${INVENTORY_NAME}.ini"
    fi
  done
}

main "${@}"
