# GitOps Deployment Project with ArgoCD on AWS EKS

This project demonstrates how to set up a GitOps workflow using **ArgoCD** on an **Amazon EKS cluster**. Applications are deployed and managed automatically based on changes committed to a GitHub repository.
---

## 🚀 Prerequisites
- AWS account with permissions to create EKS clusters and node groups
- EC2 instance or local machine with:
  - [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed
---

## 🛠️ Cluster Setup

1. **Create EKS Cluster**
2. Update kubeconfig with created cluster info by using below command.
   aws eks update-kubeconfig --name GitOps --region us-west-2
3. Create Node Group
   Add worker nodes under the cluster’s node group (via AWS console or CLI).

📦 Install ArgoCD

1.Create Namespace
   kubectl create namespace argocd
2.Install ArgoCD
   Install ArgoCD
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml

🌐 Expose ArgoCD Server
1.Patch Service to LoadBalancer
   kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'  (this will create LB, wait for 2 mins till it creates)

   Get LoadBalancer DNS
     export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
     echo $ARGOCD_SERVER
   Example output:
     a331917fd761f4992b22579a1dc23dbe-1378203488.us-west-2.elb.amazonaws.com

🔑 Login to ArgoCD
Get Initial Admin Password
  export ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

Login:
Navigate to http://<ARGOCD_SERVER> in your browser.
  Username: admin
  Password: $ARGO_PWD

🔗 Connect ArgoCD to GitHub Repo
-Go to Settings > Repositories in the ArgoCD dashboard.
 -Click Connect Repo using HTTPS.
 -Enter your GitHub repository URL.
 -Click Connect.
👉 ArgoCD will now sync manifests directly from your repo.

📂 Create Application in ArgoCD
In the ArgoCD dashboard, click New Application.
Provide:
 -Application Name
 -Project (default or custom)
 -Repository URL
 -Path to manifests
 -Click Create.
👉 ArgoCD will sync and deploy resources based on the manifests.

🎮 Example: Deploy Tetris App
Once the application is created, ArgoCD deploys the manifests.
Get the Tetris service LoadBalancer DNS:

kubectl get svc -n <tetris-namespace>
Access the app in your browser using the DNS.

🔄 GitOps Workflow
Make a change in your GitHub repo (e.g., update the app image to version2).
Commit and push the change.
ArgoCD automatically detects the new commit and redeploys the application in Kubernetes.
The updated version of the app becomes available without manual intervention.

✅ Summary
This setup enables:
  -Automated deployments via GitOps
  -Continuous synchronization between GitHub and Kubernetes
  -Easy application management through ArgoCD’s dashboard

🛠️ Issues and Fixes

1.Resetting ArgoCD Admin Password
**Issue:**  
The initial admin password secret (argocd-initial-admin-secret) may be deleted or unavailable, preventing login.
**Fix:**  
Manually reset the admin password by patching the argocd-secret:
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": { "admin.password": "NewPasswordHere", "admin.passwordMtime": "'$(date +%FT%T%Z)'" }}'

2. Pods in CrashLoopBackOff (Redis Password Missing)

   **Issue:** During deployment, ArgoCD pods went into `CrashLoopBackOff` because the Redis password secret was missing.
    **Fix:** Create the Redis secret with the required `auth` key: ```bash kubectl -n argocd create secret generic argocd-redis \ --from-literal=auth=$(openssl rand -hex 16)

    -After creating the secret, restart the Redis pod:
       kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-redis