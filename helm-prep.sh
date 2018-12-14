
#kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --service-account=tiller 
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --tiller-tls-verify
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config update
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config version

helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n cd stable/jenkins -f jenkins-helm-values.yaml --version 0.16.6 --wait
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 28080:8080 >> /dev/null &

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

