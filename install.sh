#Pre requisites
command_exists () {
    command -v $1 >/dev/null 2>&1;
}

kube_rbac_is_not_installed() {
    [[ $(kubectl cluster-info dump --namespace kube-system | grep authorization-mode | wc -l) -eq 0 ]]
}

if ! command_exists kubectl
then
    printf '%s\n' "kubectl is not installed or on the path"
    exit 
fi

if kube_rbac_is_not_installed
then
    printf '%s\n' "RBAC is not installed"
    exit 1
fi
