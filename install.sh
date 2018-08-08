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

kube_wait_for_pod_to_be_running() {
    while [[ $(kubectl get pod -n $1 | grep $2 | grep Running | wc -l) -eq 0 ]]
    do
        echo $2 not ready yet.
        sleep 5
    done
}

kube_get_service_type(){
    kubectl -n $1 get service $2 -o jsonpath='{.spec.type}'
}

kube_get_service_http(){
    service_type=$(kube_get_service_type $1 $2)

    if [ $service_type="NodePort" ]
    then
        service_host=$(kubectl -n $1 get service $2 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}');
        service_port=$(kubectl -n $1 get service $2 -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
    else
        service_host=$(kubectl -n $1 get service $2 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        service_port=$(kubectl -n $1 get service $2 -o jsonpath='{.spec.ports[?(@.name=="http")].port}')
    fi

    echo "$service_host:$service_port"
}

kube_get_service_https(){
    service_type=$(kube_get_service_type $1 $2)
    if [ $service_type="NodePort" ]
    then
        service_host=$(kubectl -n $1 get service $2 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}');
        service_port=$(kubectl -n $1 get service $2 -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    else
        service_host=$(kubectl -n $1 get service $2 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        service_port=$(kubectl -n $1 get service $2 -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    fi

    echo "$service_host:$service_port"
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

if [ ! -f certificates/dev.localhost.crt ]; then
    echo "certificates/dev.localhost.crt file not found!"
    exit 1
fi

if [ ! -f certificates/dev.localhost.key.nopassword ]; then
    echo "certificates/dev.localhost.key.nopassword file not found!"
    exit 1
fi

helm reset
kubectl create -f kubernetes/helm/helm-service-account.yaml

helm init --service-account tiller
kube_wait_for_pod_to_be_running kube-system tiller-deploy

cert=$(cat certificates/dev.localhost.crt | base64 | tr -d '\n')
cert_key=$(cat certificates/dev.localhost.key.nopassword | base64 | tr -d '\n')

cat << EOF > traefik-overrides.yml
imageTag: 1.6.5   
serviceType: NodePort
service:
  nodePorts:
    http: 31380
    https: 31390   
ssl:
    enabled: true
    enforced: true
    defaultCert: $cert
    defaultKey: $cert_key
dashboard:
    enabled: true
    domain: "traefik.dev.localhost"
rbac:
    enabled: true
EOF

#Add tracing to Treafik
#Add metrics to Traefik

helm install stable/traefik --name traefik-ingress --namespace kube-system -f traefik-overrides.yml
kube_wait_for_pod_to_be_running kube-system traefik-ingress

http_endpoint=`kube_get_service_http kube-system traefik-ingress-traefik`
https_endpoint=`kube_get_service_https kube-system traefik-ingress-traefik`

echo "Traefik is running http on http://$http_endpoint"
echo "Traefik is running https on https://$https_endpoint"
echo "If you are using a reverse proxy please configure it to point to these endpoints"

cat << EOF > kubernetes-dashboard-overrides.yml
image:
  tag: v1.8.3
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: traefik
  hosts:
      - k8s.dev.localhost
rbac:
  create: true
  clusterAdminRole: true
serviceAccount:
  name: kubernetes-dashboard
EOF

helm install stable/kubernetes-dashboard --name kubernetes-dashboard --namespace kube-system -f kubernetes-dashboard-overrides.yml
kube_wait_for_pod_to_be_running kube-system kubernetes-dashboard

helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
cat << EOF > prometheus-operator-overrides.yml

EOF
helm install coreos/prometheus-operator --name prometheus-operator --namespace prometheus-system -f prometheus-operator-overrides.yml
kube_wait_for_pod_to_be_running prometheus-system prometheus-operator

#If deploying to GKE/EKS/AKS set
#deployKubeScheduler: False
#deployKubeControllerManager: False
cat << EOF > kube-prometheus-overrides.yml
alertmanager:
  ingress:
    enabled: true
    annotations:
        kubernetes.io/ingress.class: traefik
    hosts: 
        - alertmanager.dev.localhost
prometheus:
  ingress:
    enabled: true
    annotations:
        kubernetes.io/ingress.class: traefik
    hosts: 
        - prometheus.dev.localhost
  
EOF

helm install coreos/kube-prometheus --name kube-prometheus --namespace prometheus-system -f kube-prometheus-overrides.yml
# Helm chart current doesn't allow you to set this yet
kubectl apply -f kubernetes/prometheus/grafana.ingress.yaml --name kube-prometheus-grafana --namespace prometheus-system
kube_wait_for_pod_to_be_running prometheus-system prometheus-kube-prometheus
kube_wait_for_pod_to_be_running prometheus-system kube-prometheus-exporter-kube-state
kube_wait_for_pod_to_be_running prometheus-system kube-prometheus-exporter-node
kube_wait_for_pod_to_be_running prometheus-system alertmanager-kube-prometheus
kube_wait_for_pod_to_be_running prometheus-system kube-prometheus-grafana

#helm repo add rook-master https://charts.rook.io/master
#helm search rook
#cat << EOF > rook-overrides.yml
#image:
#  tag: v0.7.1-4.g4233e03
#EOF
#helm install rook-master/rook --name rook-operator --namespace kube-system -f rook-overrides.yml
#kube_wait_for_pod_to_be_running kube-system rook-operator
#kube_wait_for_pod_to_be_running kube-system rook-agent
#kube_wait_for_pod_to_be_running kube-system rook-discover

#helm repo add rook-beta https://charts.rook.io/beta
#cat << EOF > rook-overrides.yml
#EOF
#helm install rook-beta/rook-ceph --name rook-operator --namespace kube-system -f rook-overrides.yml
#kube_wait_for_pod_to_be_running kube-system rook-ceph-operator
#kube_wait_for_pod_to_be_running kube-system rook-ceph-agent
#kube_wait_for_pod_to_be_running kube-system rook-agent
#kube_wait_for_pod_to_be_running kube-system rook-discover

kubectl apply -f kubernetes/ceph/operator.yaml
kube_wait_for_pod_to_be_running rook-ceph-system rook-ceph-operator
kube_wait_for_pod_to_be_running rook-ceph-system rook-ceph-agent
kube_wait_for_pod_to_be_running rook-ceph-system rook-discover

kubectl apply -f kubernetes/cockroachdb/operator.yaml
kube_wait_for_pod_to_be_running rook-cockroachdb-system rook-cockroachdb-operator

kubectl apply -f kubernetes/minio/operator.yaml
kube_wait_for_pod_to_be_running rook-minio-system rook-minio-operator