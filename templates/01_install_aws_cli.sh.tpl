#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/consul-cloud-init.log"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"
}

function exit_script {
  if [[ "$1" == 0 ]]; then
    log "INFO" "nomad_custom_data script finished successfully!"
  else
    log "ERROR" "nomad_custom_data script finished with error code $1."
  fi

  exit "$1"
}

function detect_os_distro {
  local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)
  local OS_DISTRO_DETECTED

  case "$OS_DISTRO_NAME" in
    "Ubuntu"*)
      OS_DISTRO_DETECTED="ubuntu"
      ;;
    "CentOS"*)
      OS_DISTRO_DETECTED="centos"
      ;;
    "Red Hat"*)
      OS_DISTRO_DETECTED="rhel"
      ;;
    "Amazon Linux"*)
      OS_DISTRO_DETECTED="al2023"
      ;;
    *)
      log "ERROR" "'$OS_DISTRO_NAME' is not a supported Linux OS distro for this Consul module."
      exit_script 1
			;;
  esac

  echo "$OS_DISTRO_DETECTED"
}

function install_awscli {
  local OS_DISTRO="$1"
  local OS_VERSION=$(grep "^VERSION=" /etc/os-release | cut -d"\"" -f2)

  if command -v aws > /dev/null; then
    log "INFO" "Detected 'aws-cli' is already installed. Skipping."
  else
    log "INFO" "Installing 'aws-cli'."
    curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    if command -v unzip > /dev/null; then
      unzip -qq awscliv2.zip
    elif command -v busybox > /dev/null; then
      busybox unzip -qq awscliv2.zip
    else
      log "WARNING" "No 'unzip' utility found. Attempting to install 'unzip'."
      if [[ "$OS_DISTRO" == "ubuntu" || "$OS_DISTRO" == "debian" ]]; then
        apt-get update -y
        apt-get install unzip -y
      elif [[ "$OS_DISTRO" == "centos" || "$OS_DISTRO" == "rhel" ]]; then
        yum install unzip -y
      elif [[ "$OS_DISTRO" == "al2023" ]]; then
        dnf install unzip -y
        log "INFO" "Enabling gnupg2-full for Amazon Linux 2023."
        dnf swap gnupg2-minimal gnupg2-full -y
      else
        log "ERROR" "Unable to install required 'unzip' utility. Exiting."
        exit_script 2
      fi
      unzip -qq awscliv2.zip
    fi
    ./aws/install > /dev/null
    rm -f ./awscliv2.zip && rm -rf ./aws
  fi
}

log "INFO" "Determining Linux operating system distro..."
OS_DISTRO=$(detect_os_distro)
log "INFO" "Detected Linux OS distro is '$OS_DISTRO'."
OS_MAJOR_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d"\"" -f2 | cut -d"." -f1)
log "INFO" "Detected OS major version is '$OS_MAJOR_VERSION'."
install_awscli "$OS_DISTRO"
