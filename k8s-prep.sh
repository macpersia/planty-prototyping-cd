# Provision a Kubernetes cluster using GKE. This step can take up to several minutes to complete.
# The extra scopes enable Jenkins to access Cloud Source Repositories and Container Registry.
#gcloud container clusters create planty-prototyping-cd-cluster --machine-type n1-standard-2 --num-nodes 1 --scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform"

## Once you're done with CD, you can suspend the cluster by downsizing it to 0 nodes, using: 
##gcloud container clusters resize planty-prototyping-cd-cluster --size 0

##gcloud components install kubectl
#sudo apt get install kubectl
sudo snap install microk8s --classic
sudo snap alias microk8s.kubectl kubectl
microk8s.enable dns 

kubectl cluster-info

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

# Something like: kubectl cp ./nexus-data repo-nexus-6cd55959b5-tqffw:./
# Then inside the pod: cd nexus-data; echo -e "\n# Added by Hadi\nnexus.security.anticsrftoken.enabled=false" >> etc/nexus.properties; cp my-db-backups/* restore-from-backup/; cd db; kill 1; rm -rf accesslog analytics audit component config security;

# MANUAL! Add a Nexus role named "deployer-role" with these privileges: nx-component-upload & nx-repository-view-*-*-edit, and having nx-anonymous role too.
# MANUAL! Add a Nexus user with "deployer" as ID, and these roles: deployer-role & nx-anonymous.

# MANUAL! Add Nexus pod's IP as "repo-nexus-service" to /etc/hosts 

# MANUAL! For local development, configure both Maven and NPM to point to the Nexus on k8s

# Prepare Jenkins
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n cd stable/jenkins --version 0.25.1 -f jenkins-helm-values.yaml --wait
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 28080:8080 >> /dev/null &

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

# MANUAL! Install ThinBackup plugin & restore Jenkins backups

# MANUAL! Add credentials for Nexus user "deployer"

## To enable webhooks to localhost
#sudo npm install bespoken-tools -g



