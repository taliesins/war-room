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
while [[ $(kubectl get pod -n kube-system | grep tiller-deploy | grep Running | wc -l) -eq 0 ]]
do
  echo tiller-deploy not ready yet.
  sleep 5
done

cat << EOF > traefik-overrides.yml
imageTag: 1.6.5   
serviceType: NodePort                               
ssl:
    enabled: true
    enforced: true
dashboard:
    enabled: true
    domain: "traefik.dev.localhost"
rbac:
    enabled: true
EOF

#Add tracing to Treafik
#Add metrics to Traefik

helm install stable/traefik --name traefik-ingress --namespace kube-system -f traefik-overrides.yml
while [[ $(kubectl get pod -n kube-system | grep traefik-ingress | grep Running | wc -l) -eq 0 ]]
do
  echo traefik-ingress not ready yet.
  sleep 5
done


