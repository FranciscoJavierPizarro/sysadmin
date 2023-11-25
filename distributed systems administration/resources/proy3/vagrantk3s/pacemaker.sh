ID=$(cat /etc/os-release | awk -F= '/^ID=/{print $2}' | tr -d '"')

case "${ID}" in
  debian|ubuntu)
    apt-get update
    apt-get install -y pacemaker corosync haveged crmsh
    ;;
  *)
    echo "Distro '${ID}' not supported" 2>&1
    exit 1
    ;;
esac