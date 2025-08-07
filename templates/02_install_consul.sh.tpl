#!/usr/bin/env bash
export SHELLOPTS
set -euo pipefail

PRODUCT="consul"
CONSUL_VERSION="${consul_version}"
VERSION=$CONSUL_VERSION
CONSUL_DIR_BIN="/usr/bin/"
CONSUL_DIR_LICENSE="/opt/consul"
CONSUL_USER="consul"
CONSUL_GROUP="consul"

LOGFILE="/var/log/consul-cloud-init.log"

function log {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local log_entry="$timestamp [$level] - $message"

  echo "$log_entry" | tee -a "$LOGFILE"
}

# GOARCH=$(uname -m)
# if [ "$GOARCH" == "x86_64" ]
# then
#   DLARCH="amd64"
# elif [ "$GOARCH" == "aarch64" ]
# then
#   DLARCH="arm64"
# else
#   DLARCH=$GOARCH
# fi

function detect_architecture {
  local ARCHITECTURE=""
  local OS_ARCH_DETECTED=$(uname -m)

  case "$OS_ARCH_DETECTED" in
    "x86_64"*)
      ARCHITECTURE="linux_amd64"
      ;;
    "aarch64"*)
      ARCHITECTURE="linux_arm64"
      ;;
		"arm"*)
      ARCHITECTURE="linux_arm"
			;;
    *)
      log "ERROR" "Unsupported architecture detected: '$OS_ARCH_DETECTED'. "
		  exit_script 1
  esac

  echo "$ARCHITECTURE"

}

function checksum_verify {
  local OS_ARCH="$1"

  # https://www.hashicorp.com/en/trust/security
  # checksum_verify downloads the $$PRODUCT binary and verifies its integrity
  log "INFO" "Verifying the integrity of the $${PRODUCT} binary."
  export GNUPGHOME=./.gnupg
  log "INFO" "Importing HashiCorp GPG key."
  sudo curl -s https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import

	log "INFO" "Downloading $${PRODUCT} binary"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_"$${OS_ARCH}".zip
	log "INFO" "Downloading $${PRODUCT} Enterprise binary checksum files"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_SHA256SUMS
	log "INFO" "Downloading $${PRODUCT} Enterprise binary checksum signature file"
  sudo curl -Os https://releases.hashicorp.com/"$${PRODUCT}"/"$${VERSION}"/"$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig
  log "INFO" "Verifying the signature file is untampered."
  gpg --verify "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS
	if [[ $? -ne 0 ]]; then
		log "ERROR" "Gpg verification failed for SHA256SUMS."
		exit_script 1
	fi
  if [ -x "$(command -v sha256sum)" ]; then
		log "INFO" "Using sha256sum to verify the checksum of the $${PRODUCT} binary."
		sha256sum -c "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS --ignore-missing
	else
		log "INFO" "Using shasum to verify the checksum of the $${PRODUCT} binary."
		shasum -a 256 -c "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS --ignore-missing
	fi
	if [[ $? -ne 0 ]]; then
		log "ERROR" "Checksum verification failed for the $${PRODUCT} binary."
		exit_script 1
	fi

	log "INFO" "Checksum verification passed for the $${PRODUCT} binary."

	log "INFO" "Removing the downloaded files to clean up"
	sudo rm -f "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS "$${PRODUCT}"_"$${VERSION}"_SHA256SUMS.sig

}

# install_consul_binary downloads the $${PRODUCT} binary and puts it in dedicated bin directory
function install_consul_binary {
  local OS_ARCH="$1"

  log "INFO" "Installing $${PRODUCT} binary to: $CONSUL_DIR_BIN..."

	sudo unzip "$${PRODUCT}"_"$${CONSUL_VERSION}"_"$${OS_ARCH}".zip  consul -d $CONSUL_DIR_BIN
	sudo unzip "$${PRODUCT}"_"$${CONSUL_VERSION}"_"$${OS_ARCH}".zip -x consul -d $CONSUL_DIR_LICENSE
	sudo rm -f "$${PRODUCT}"_"$${CONSUL_VERSION}"_"$${OS_ARCH}".zip

	# Set the permissions for the $S{PRODUCT} binary
	sudo chmod 0755 $CONSUL_DIR_BIN/consul
	sudo chown $CONSUL_USER:$CONSUL_GROUP $CONSUL_DIR_BIN/consul

	# Create a symlink to the $${PRODUCT} binary in /usr/local/bin
	sudo ln -sf $CONSUL_DIR_BIN/consul /usr/local/bin/consul

	log "INFO" "$${PRODUCT} binary installed successfully at $CONSUL_DIR_BIN/consul"
}

OS_ARCH=$(detect_architecture)
log "INFO" "Detected architecture: $OS_ARCH"
checksum_verify "$OS_ARCH"
log "INFO" "Checksum verification completed successfully for $PRODUCT version $CONSUL_VERSION"
log "INFO" "Installing $PRODUCT version $CONSUL_VERSION for architecture $OS_ARCH"
install_consul_binary "$OS_ARCH"

# curl -Lo consul.zip https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_$DLARCH.zip

# unzip consul.zip
# sudo install consul /usr/local/bin/

# rm -f consul.zip consul
