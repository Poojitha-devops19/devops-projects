# Cloud Native Voting App on AWS EKS

## 📌 Overview
This project demonstrates deploying a **cloud native voting application** on **Amazon EKS (Elastic Kubernetes Service)**.  
It includes:
- **Frontend** (React app)
- **Backend API** (Go service)
- **Database** (MongoDB StatefulSet with replica set)

The setup showcases Kubernetes concepts like **Deployments, Services, StatefulSets, Headless Services, PersistentVolumes**, and integration with **AWS EBS CSI driver** for storage.

---

## 🛠️ Prerequisites
- AWS account with permissions to create EKS clusters and EC2 instances
- IAM roles for **EKS control plane** and **EC2 worker nodes**
- AWS CLI and `kubectl` installed
- Git installed for cloning manifests
- EBS CSI driver enabled in the cluster

---

## ⚙️ Setup Steps

### 1. Create EKS Cluster
- Create an EKS cluster with a **NodeGroup** (2 nodes of `t2.medium` instance type).
- Optionally create an EC2 `t2.micro` instance for administration.

### 2. IAM Role for EC2
Attach the following IAM policy to the EC2 admin instance (to connect to cluster from control plane, kubectl needs permissions to connect to cluster):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:ListUpdates",
      "eks:AccessKubernetesApi"
    ],
    "Resource": "*"
  }]
}

### 3. Install tools
  # Install kubectl
     curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.11/2023-03-17/bin/linux/amd64/kubectl
     chmod +x ./kubectl
     sudo cp ./kubectl /usr/local/bin
     export PATH=/usr/local/bin:$PATH

 # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

##4. Configure kubectl
  bash
  aws eks update-kubeconfig --name cluster1 --region us-west-2
  kubectl get nodes

##5. Clone Repo
   clone your manifests files in EC2.

##6.Create Namespace
   bash
   kubectl create ns ns1
   kubectl config set-context --current --namespace ns1


📄 MongoDB Setup
1. Deploy StatefulSet + Service
bash
kubectl apply -f mongo-statefulset.yaml (3 MongoDB Pods (mongo-0, mongo-1, mongo-2)
                                 3 PVCs (each bound to an EBS disk for persistence))
kubectl apply -f mongo-service.yaml(1 Headless Service (mongo) providing DNS for Pod‑to‑Pod communication)
(PV (PersistentVolume) → “Cluster‑level storage resource, like an actual EBS disk.”
PVC (PersistentVolumeClaim) → “Pod’s request for storage, bound to a matching PV.”)

test with this kubectl get svc -n ns1
to make default namespace instead of adding everytime - kubectl config set-context --current --namespace

2.Initialize Replica Set

cat << EOF | kubectl exec -it mongo-0 -- mongo
rs.initiate();
sleep(2000);
rs.add("mongo-1.mongo:27017");
sleep(2000);
rs.add("mongo-2.mongo:27017");
sleep(2000);
cfg = rs.conf();
cfg.members[0].host = "mongo-0.mongo:27017";
rs.reconfig(cfg, {force: true});
sleep(5000);
EOF

Verify:
kubectl exec -it mongo-0 -- mongo --eval "rs.status()" | grep "PRIMARY\|SECONDARY" (This command checks the health and role of each MongoDB Pod in the replica set)

3.Load Sample Data

cat << EOF | kubectl exec -it mongo-0 -- mongo
use langdb;
db.languages.insert({"name" : "csharp", "codedetail" : { "usecase" : "system, web, server-side", "rank" : 5, "compiled" : false, "homepage" : "https://dotnet.microsoft.com/learn/csharp", "download" : "https://dotnet.microsoft.com/download/", "votes" : 0}});
db.languages.insert({"name" : "python", "codedetail" : { "usecase" : "system, web, server-side", "rank" : 3, "script" : false, "homepage" : "https://www.python.org/", "download" : "https://www.python.org/downloads/", "votes" : 0}});
db.languages.insert({"name" : "javascript", "codedetail" : { "usecase" : "web, client-side", "rank" : 7, "script" : false, "homepage" : "https://en.wikipedia.org/wiki/JavaScript", "download" : "n/a", "votes" : 0}});
db.languages.insert({"name" : "go", "codedetail" : { "usecase" : "system, web, server-side", "rank" : 12, "compiled" : true, "homepage" : "https://golang.org", "download" : "https://golang.org/dl/", "votes" : 0}});
db.languages.insert({"name" : "java", "codedetail" : { "usecase" : "system, web, server-side", "rank" : 1, "compiled" : true, "homepage" : "https://www.java.com/en/", "download" : "https://www.java.com/en/download/", "votes" : 0}});
db.languages.insert({"name" : "nodejs", "codedetail" : { "usecase" : "system, web, server-side", "rank" : 20, "script" : false, "homepage" : "https://nodejs.org/en/", "download" : "https://nodejs.org/en/download/", "votes" : 0}});

db.languages.find().pretty();
EOF

4.Create Secret(which holds username and password for mongo db database)
kubectl apply -f mongo-secret.yaml

Kubectl get all - 3 pods for mongo, 2 pods for api, one service (cluster ip) for mongo, deployment for api, replicaset for api, statefulset for mongo

📄 API Setup (loadbalancer and pods)
1. Deploy API
kubectl apply -f api-deployment.yaml

2. Expose API
kubectl expose deploy api \
 --name=api \
 --type=LoadBalancer \
 --port=80 \
 --target-port=8080

3. Test API
API_ELB_PUBLIC_FQDN=$(kubectl get svc api -ojsonpath="{.status.loadBalancer.ingress[0].hostname}")
curl -s $API_ELB_PUBLIC_FQDN/languages | jq .

📄 Frontend Setup (loadbalancer and pods)

1. Deploy Frontend
kubectl apply -f frontend-deployment.yaml

2. Expose Frontend
kubectl expose deploy frontend \
 --name=frontend \
 --type=LoadBalancer \
 --port=80 \
 --target-port=8080

3. Test Frontend
FRONTEND_ELB_PUBLIC_FQDN=$(kubectl get svc frontend -ojsonpath="{.status.loadBalancer.ingress[0].hostname}")
echo http://$FRONTEND_ELB_PUBLIC_FQDN
(That command fetches the public URL of your frontend LoadBalancer so you can open the React app in a browser.)

🛠️ Issues and Fixes
	 Issue: Nodes stuck in NotReady state
		• After creating the EKS cluster and node group, all nodes remained in NotReady.
		• kubectl describe node showed:
           Ready: False
           NetworkPluginNotReady: cni plugin not initialized
		    • System pods (e.g. metrics-server) were stuck in Pending because no Ready nodes existed.
		    • The aws-node DaemonSet (Amazon VPC CNI plugin) was missing from the kube-system namespace.
	 Fix:
	    Installed the Amazon VPC CNI plugin as an EKS add‑on:	
         aws eks create-addon --cluster-name cluster1 --addon-name vpc-cni --region us-west-2
	 Learning from this fix:
	    The Container Network Interface (CNI) plugin is what provides networking for Pods in Kubernetes. In EKS, the Amazon VPC CNI plugin lets Pods get IP addresses directly from the VPC, enabling them to communicate with each other and with other AWS resources. Without it, nodes can’t initialize networking, so they stay in NotReady.



