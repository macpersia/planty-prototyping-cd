#gcloud projects create planty-prototyping-cd-k8s

#gcloud compute networks create planty-prototyping-cd-network
# Instances on this network will not be reachable until firewall rules
# are created. As an example, you can allow all internal traffic between
# instances as well as SSH, RDP, and ICMP by running:
##gcloud compute firewall-rules create <FIREWALL_NAME> --network planty-prototyping-cd-network --allow tcp,udp,icmp --source-ranges <IP_RANGE>
#gcloud compute firewall-rules create planty-prototyping-cd-fw-rules --network planty-prototyping-cd-network --allow tcp,udp,icmp --source-service-accounts=macpersia.it@gmail.com
#gcloud compute firewall-rules update planty-prototyping-cd-fw-rules --allow tcp:22,tcp:3389,icmp

# Provision a Kubernetes cluster using GKE. This step can take up to several minutes to complete.
# The extra scopes enable Jenkins to access Cloud Source Repositories and Container Registry.
##gcloud container clusters create planty-prototyping-cd-cluster --network planty-prototyping-cd-network --machine-type n1-standard-1 --disk-size=30Gi --enable-autoscaling --max-nodes 3 --min-nodes 0 --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw,cloud-platform"
#gcloud container clusters create planty-prototyping-cd-cluster --network planty-prototyping-cd-network --machine-type n1-standard-1 --disk-size=50Gi --num-nodes 3 --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw,cloud-platform"

## On another machine, you can also fetch the config of a previously created cluster, using:
##gcloud container clusters get-credentials planty-prototyping-cd-cluster

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

##wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
sudo snap install helm --classic

#helm init --service-account=tiller
##helm init --tiller-tls-verify
#helm update
#helm version
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config init --service-account=tiller 
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config update
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config version

# Make the internet accessible to pods 
sudo iptables -A FORWARD -i enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i cbr0 -j ACCEPT

# Prepare Nexus
# There's an unresolved issue with this charm
#helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n repo stable/sonatype-nexus --version 1.15.0 --wait
#kubectl run repo-nexus --image=sonatype/nexus3
kubectl create -f nexus-data-pvc.yaml 
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
helm --kubeconfig /snap/microk8s/current/configs/kubelet.config install -n cd stable/jenkins --version 0.39.0 -f jenkins-helm-values.yaml --wait
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 28080:8080 >> /dev/null &

printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode); echo

# MANUAL! Install ThinBackup plugin & restore Jenkins backups

# MANUAL! Add credentials for Nexus user "deployer"

## To enable webhooks to localhost
#sudo npm install bespoken-tools -g



