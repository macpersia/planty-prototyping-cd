sudo snap install microk8s --classic
sudo snap alias microk8s.kubectl kubectl
microk8s.enable dns 
#kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

microk8s.enable storage
sudo snap install helm --classic
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --service-account=tiller 
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --tiller-tls-verify
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config update
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config version

# Make the internet accessible to pods 
sudo iptables -A FORWARD -i enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i cbr0 -j ACCEPT

# Prepare Nexus
# There's an unresolved issue with this charm
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n repo stable/sonatype-nexus --version 1.15.0 --wait
#kubectl run repo-nexus --image=sonatype/nexus3
kubectl create -f nexus-deployment.yaml 
kubectl create -f nexus-service.yaml

# MANUAL! Restore Nexus Blobs and DBs backups

# MANUAL! Add a Nexus role named "deployer-role" with these privileges: nx-component-upload & nx-repository-view-*-*-edit, and having nx-anonymous role too.
# MANUAL! Add a Nexus user with "deployer" as ID, and these roles: deployer-role & nx-anonymous.

# MANUAL! Add Nexus pod's IP as "repo-nexus-service" to /etc/hosts 

# MANUAL! For local development, configure both Maven and NPM to point to the Nexus on k8s

# Prepare Jenkins
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n cd stable/jenkins --version 0.25.1 -f jenkins-helm-values.yaml --wait
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 28080:8080 >> /dev/null &

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

# ATTENTION! Remember to install ThinBackup plugin & restore Jenkins backups

# Add credentials for Nexus user "deployer"

