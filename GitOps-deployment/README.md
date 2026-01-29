# GitOps Deployment Project with ArgoCD on AWS EKS

This project demonstrates how to set up a GitOps workflow using **ArgoCD** on an **Amazon EKS cluster**. Applications are deployed and managed automatically based on changes committed to a GitHub repository.
---

## 🚀 Prerequisites
- AWS account with permissions to create EKS clusters and node groups
- EC2 instance or local machine with:
  - [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed
---

## 1.🛠️ Cluster Setup

    1. **Create EKS Cluster**
    2. Update kubeconfig with created cluster info by using below command.
       aws eks update-kubeconfig --name GitOps --region us-west-2
    3. Create Node Group
       Add worker nodes under the cluster’s node group (via AWS console or CLI).

**2.📦 Install ArgoCD**

     1.Create Namespace
       kubectl create namespace argocd
     2.Install ArgoCD
       Install ArgoCD
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml

**i.🌐 Expose ArgoCD Server**

     1.Patch Service to LoadBalancer
       kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'  (this will create LB, wait        for 2 mins till it creates)
     2.Get LoadBalancer DNS
       export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output  '.status.loadBalancer.ingress[0].hostname')
     3.Testing-
       echo $ARGOCD_SERVER
       Example output:
        a331917fd761f4992b22579a1dc23dbe-1378203488.us-west-2.elb.amazonaws.com

**ii.🔑 Login to ArgoCD**

    Get Initial Admin Password
     export ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    Login:
      Navigate to http://<ARGOCD_SERVER> in your browser.
        Username: admin
        Password: $ARGO_PWD

**3.Connecting Repository**

   **i.🔗 Connect ArgoCD to GitHub Repo**
       -Go to Settings > Repositories in the ArgoCD dashboard.
       -Click Connect Repo using HTTPS.
       -Enter your GitHub repository URL.
        -Click Connect.
     👉 ArgoCD will now sync manifests directly from your repo.

   **ii.📂 Create Application in ArgoCD**
      In the ArgoCD dashboard, click New Application.
      Provide:
        -Application Name
        -Project (default or custom)
        -Repository URL
        -Path to manifests
        -Click Create.
      👉 ArgoCD will sync and deploy resources based on the manifests.

    **🎮 Example: Deploy Tetris App**
        1.Once the application is created, ArgoCD deploys the manifests.
        2.Get the Tetris service LoadBalancer DNS:
            kubectl get svc -n <tetris-namespace>
        3.Access the app in your browser using the DNS.

   **🔄 GitOps Workflow**
      1.Make a change in your GitHub repo (e.g., update the app image to version2).
      2.Commit and push the change.
      3.ArgoCD automatically detects the new commit and redeploys the application in Kubernetes.
      4.The updated version of the app becomes available without manual intervention.

    **✅ Summary**
      This setup enables:
       1.Automated deployments via GitOps
       2.Continuous synchronization between GitHub and Kubernetes
       3.Easy application management through ArgoCD’s dashboard

**🛠️ Issues and Fixes**
   **1.Resetting ArgoCD Admin Password**
       **Issue:**  
          The initial admin password secret (argocd-initial-admin-secret) may be deleted or unavailable, preventing login.
       **Fix:**  
          Manually reset the admin password by patching the argocd-secret:
             kubectl -n argocd patch secret argocd-secret \
              -p '{"stringData": { "admin.password": "NewPasswordHere", "admin.passwordMtime": "'$(date +%FT%T%Z)'" }}'

   ** **2. Pods in CrashLoopBackOff**** (Redis Password Missing)
           **Issue:** During deployment, ArgoCD pods went into `CrashLoopBackOff` because the Redis password secret                         was missing.
            **Fix:** Create the Redis secret with the required `auth` key: ```bash kubectl -n argocd create secret                     generic argocd-redis \ --from-literal=auth=$(openssl rand -hex 16)
                -After creating the secret, restart the Redis pod:
                    kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-redis
     ** 3. LB stuck with EXTERNAL-IP <pending>**
     **  issue**: tetris-service was stuck with EXTERNAL-IP <pending>.
		           • The event log showed:
                    Failed build model due to unable to resolve at least one subnet (0 match VPC and tags:    [kubernetes.io/role/internal-elb])
		        • This meant EKS couldn’t find any subnets with the required tags to place the load balancer.
	      **  Fix**
		       •  added the correct AWS subnet tags:
			            ○ Cluster ownership tag → kubernetes.io/cluster/GitOps = owned
			            ○ Role tags → kubernetes.io/role/elb = 1 for public subnets, or kubernetes.io/role/internal-elb =  1 for private subnets
		      • These tags tell EKS:
			       ○ Which subnets belong to your cluster.
			       ○ Whether they should be used for public or internal load balancers.
	      Once the tags were applied, AWS was able to provision the load balancer, and your service got a working              external DNS name:
         ec51b1c3bcf64f7d90b024f8ca9830f-102008180.us-west-2.elb.amazonaws.com
