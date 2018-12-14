
#kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --service-account=tiller 
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --tiller-tls-verify
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config update
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config version

helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n cd stable/jenkins --version 0.25.1 -f jenkins-helm-values.yaml --wait
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 28080:8080 >> /dev/null &

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo


# There's an unresolved issue with this charm
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n repo stable/sonatype-nexus --version 1.15.0 --wait

#kubectl run repo-nexus --image=sonatype/nexus3

kubectl create -f nexus-deployment.yaml 
kubectl create -f nexus-service.yaml

