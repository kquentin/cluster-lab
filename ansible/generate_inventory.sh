#!/bin/bash

set -Eeuo pipefail

INVENTORY_NAME="default"
readonly INVENTORY_NAME

NET_PREFIX="10.28.28"
readonly NET_PREFIX

main() {
  local -a active_hosts;
  while read -r ip; do # optimize query speed with a subshell, redirect output to the `active_hosts` array.
    active_hosts+=("${ip}") 
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
  )

  [[ -n "${active_hosts[*]}" ]] || printf "Error: No active hosts found.\n"

  for ip_address in "${active_hosts[@]}"; do
    local id; id=$(printf "%s" "${ip_address}" | awk -F'.' '{print $4}')
    printf "pc%s ansible_host=%s\n" "${id}" "${ip_address}"
  done > "${INVENTORY_NAME}".ini

  sed -i "1i\\[$INVENTORY_NAME]" "${INVENTORY_NAME}".ini
}

main "${@}"
