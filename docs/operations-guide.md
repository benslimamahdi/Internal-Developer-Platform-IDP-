# 🕹️ Operations Guide

This guide details how to run, explore, and verify the Internal Developer Platform (IDP).

## 1. Prerequisites
Ensure you have the following installed on your Windows machine:
*   [Docker Desktop](https://www.docker.com/) (Make sure the Engine is running)
*   [Kind](https://kind.sigs.k8s.io/) (`choco install kind`)
*   [Helm](https://helm.sh/) (`choco install kubernetes-helm`)
*   [Kubectl](https://kubernetes.io/docs/tasks/tools/) (`choco install kubernetes-cli`)

## 2. Starting the Platform
We provide a PowerShell script to bootstrap the Kind cluster and install the control plane (Argo CD).

```powershell
.\scripts\bootstrap-cluster.ps1
```

*   **What this does**:
    1.  Creates a Kind cluster named `idp-platform`.
    2.  Installs Nginx Ingress Controller.
    3.  Installs Argo CD.
    4.  Outputs the initial Argo CD admin password.

## 3. Accessing Services (Port Forwarding)
Since we are running locally, we use `kubectl port-forward` to access the services. Open separate terminals for each of these commands (they must stay running).

### Control Plane: Argo CD
*   **Command**: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
*   **URL**: [https://localhost:8080](https://localhost:8080)
*   **Credentials**: User `admin`, Password (from bootstrap output).

### Developer Portal: Backstage
*   **Command**: `kubectl port-forward svc/backstage -n backstage 7007:7007`
*   **URL**: [http://localhost:7007](http://localhost:7007)

### Observability: Grafana
*   **Command**: `kubectl port-forward svc/prometheus-grafana -n observability 3000:80`
*   **URL**: [http://localhost:3000](http://localhost:3000)

## 4. Verification & Exploration

### A. Check GitOps Status (Argo CD)
1.  Log in to Argo CD.
2.  You should see the "App-of-Apps" pattern.
3.  The root application should spawn children: `vault`, `backstage`, `policies`, `observability`.
4.  Wait for all hearts to turn Green 💚.

### B. Scaffold a New Service (Backstage)
1.  Go to Backstage ([http://localhost:7007](http://localhost:7007)).
2.  Click **Create** in the sidebar.
3.  Select the **React Frontend** template.
4.  Fill in the form (Name: `demo-app`, Owner: `guest`).
5.  Click **Next** and watch it scaffold! (Note: Publishing to GitHub requires a `GITHUB_TOKEN` in `app-config.local.yaml`, but the dry-run works without it).

### C. Test Security Policies (Kyverno)
Try to run a "bad" pod (privileged root container) to see the platform deny it.

```bash
kubectl run priv-pod --image=nginx --privileged
```

**Expected Output**:
```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
policy Pod/priv-pod for resource violation:
privileged-containers:
  privileged-containers: 'Privileged mode is not allowed. Set securityContext.privileged to false.'
```

## 5. Portfolio Screenshots
Refer to `docs/screenshot_guide.md` for the exact list of screenshots to capture for the README.
