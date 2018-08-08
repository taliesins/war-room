#Pre requisites
command_exists () {
    command -v $1 >/dev/null 2>&1;
}

kube_is_rbac_not_installed() {
    [[ $(kubectl cluster-info dump --namespace kube-system | grep authorization-mode | wc -l) -eq 0 ]]
}

kube_is_admission_controller_not_installed() {
    [[ $(kubectl describe pod --namespace kube-system $(kubectl get pods --namespace kube-system | grep api | cut -d ' ' -f 1) | grep admission-control | grep $1 | wc -l) -eq 0 ]]
}

kube_is_MutatingAdmissionWebhook_admission_controller_not_installed() {
    kube_is_admission_controller_not_installed MutatingAdmissionWebhook
}

kube_is_ValidatingAdmissionWebhook_admission_controller_not_installed() {
    kube_is_admission_controller_not_installed ValidatingAdmissionWebhook
}

if ! command_exists kubectl
then
    printf '%s\n' "kubectl is not installed or on the path"
    exit 
fi

if ! command_exists helm
then
    printf '%s\n' "helm is not installed or on the path"
    exit 
fi

if kube_is_rbac_not_installed
then
    printf '%s\n' "RBAC is not installed"
    exit 1
fi

if kube_is_MutatingAdmissionWebhook_admission_controller_not_installed
then
    printf '%s\n' "MutatingAdmissionWebhook admission controller is not installed"
    exit 1
fi

if kube_is_ValidatingAdmissionWebhook_admission_controller_not_installed
then
    printf '%s\n' "ValidatingAdmissionWebhook admission controller is not installed"
    exit 1
fi

helm reset
kubectl create -f kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller
