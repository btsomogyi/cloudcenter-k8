
# Reformat simple comma separated list of values for each
# list item to be surrounded by prepend and append values
augmentCsvList() {
  local __resultvar=$1
  local __input=$2
  local __prepend=$3
  local __append=$4
  local __output

  IFS=',' read -a addr <<< "$__input"

  count=${#addr[@]}
  index=0

  while [ "$index" -lt "$count" ]; do
    if [ "$index" -eq "0" ]; then
      __output="${__prepend}${addr[${index}]}${__append}"
    else
      __output="${__output},${__prepend}${addr[${index}]}${__append}"
    fi
    let "index++"
  done

  eval $__resultvar="'$__output'"

}

# Retrieve files from other node
retrieveFiles() {
  local __target=$1
  local __path=$2
  local __files=$3

  if [ ! -z "$__target" ]; then
    for i in ${__files} ; do
      scp -o StrictHostKeyChecking=no ${__target}:${__path}/${i} ${__path}/.
    done
  else
    log "[${TIER} ${CMD} retrieveFiles()] Error: target host undefined"
    exit 127
  fi
}

# CLUSTER_CIDRm to other nodes
pushFiles() {
  local __targets=$1
  local __path=$2
  local __files=$3

  for i in ${__files} ; do
    for j in ${__targets} ; do
      scp -o StrictHostKeyChecking=no ${__path}/${i} ${j}:${__path}/.
    done
  done
}

# Run command on other nodes
runRemoteCommand() {
  local __target=$1
  local __output=$2
  local __cmd=$3

  ssh -o StrictHostKeyChecking=no -c "${__cmd}"
}

# Approve TLS certs on remote Controller
approveTlsCerts() {
  local __target=$1
  local __nodes=$2
  local __timeout=$3

  local __count=0
  while [ ${__count} -lt ${__timeout} ]; do
    __cmdoutput=""
    runRemoteCommand ${__target} __cmdoutput 'kubectl get csr'

    echo $__cmdoutput

    let "__count++"
    sleep 60
  done

}

# Standard get for external files
downloadFile() {
  local __file="$1"

  echo "Downloading ${__file}..."
  wget --tries=3 -q $__file
}

# Parse CloudCenter Userenv variables
prepareEnvironment() {

  # Preprocess environment data
  if [ ! -z $CliqrTier_k8lb_IP ]; then
    local __K8_LB_IP="${CliqrTier_k8lb_IP}"
    local __K8_LB_PUBIP="${CliqrTier_k8lb_PUBLIC_IP}"
  else
    local __K8_LB_IP="${CliqrTier_k8lb_PUBLIC_IP}"
    local __K8_LB_PUBIP="${CliqrTier_k8lb_PUBLIC_IP}"
  fi
  if [ ! -z $CliqrTier_k8worker_IP ]; then
    local __K8_WKR_IP="$CliqrTier_k8worker_IP"
  else
    local __K8_WKR_IP="$CliqrTier_k8worker_PUBLIC_IP"
  fi
  if [ ! -z $CliqrTier_k8manager_IP ]; then
    local __K8_MGR_IP="$CliqrTier_k8manager_IP"
  else
    local __K8_MGR_IP="$CliqrTier_k8manager_PUBLIC_IP"
  fi
  if [ ! -z $CliqrTier_k8etcd_IP ]; then
    local __K8_ETCD_IP="$CliqrTier_k8etcd_IP"
  else
    local __K8_ETCD_IP="$CliqrTier_k8etcd_PUBLIC_IP"
  fi

  # Create IP addr and name arrays
  IFS=',' read -a wkr_ip <<< "$__K8_WKR_IP"
  IFS=',' read -a mgr_ip <<< "$__K8_MGR_IP"
  IFS=',' read -a etcd_ip <<< "$__K8_ETCD_IP"
  IFS=',' read -a etcd_name <<< "$CliqrTier_k8etcd_HOSTNAME"

  # Set final global variables with addresses
  K8_PUBLIC_ADDR=${__K8_LB_PUBIP}
  LB_ADDR=${__K8_LB_IP}
  ETCD_ADDRS=${__K8_ETCD_IP}
  MGR_ADDRS=${__K8_MGR_IP}
  WKR_ADDRS=${__K8_WKR_IP}

  #KUBERNETES_PUBLIC_ADDR="$__K8_LB_IP"
  #KUBERNETES_MGR_ADDRS="$__K8_MGR_IP"
  #ETCD_ADDRS="$__K8_ETCD_IP"
  #SERVICE_CLUSTER_IP_RANGE="$ServiceClusterIpRange"
  #SERVICE_CLUSTER_ROUTER="$ServiceClusterRouter"

  SERVICE_CIDR="${ServiceClusterIpRange}"
  SERVICE_RTR="${ServiceClusterRouter}"
  CLUSTER_CIDR="${K8ClusterCIDR}"
  CLUSTER_NAME="${ClusterName}"

  export

  if [ ! -z "$DEBUG" ]; then
    env
  fi

}

# Use agent logging facility
log() {
	if [ -n "$USE_PROFILE_LOG"  -a "$USE_PROFILE_LOG" == "true" ];then
	    echo "$*"
	fi
}
