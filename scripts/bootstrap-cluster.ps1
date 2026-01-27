# Check if Kind is installed
if (-not (Get-Command "kind" -ErrorAction SilentlyContinue)) {
    Write-Error "Kind is not installed. Please install specific version or use chocolatey: choco install kind"
    exit 1
}

# Check if kubectl is installed
if (-not (Get-Command "kubectl" -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed."
    exit 1
}

# --- RESET CLUSTER ---
# Check if cluster exists and delete it
$clusters = kind get clusters
if ($clusters -contains "idp-platform") {
    Write-Host "Existing cluster 'idp-platform' found. Deleting..."
    kind delete cluster --name idp-platform
}

# --- CREATE CLUSTER ---
Write-Host "Creating Kind Cluster 'idp-platform'..."
$kindConfig = @"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
"@

$kindConfig | kind create cluster --name idp-platform --config -

# --- INSTALL NGINX INGRESS ---
# (Essential for accessing services)
Write-Host "Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress
Write-Host "Waiting for Ingress Controller..."
# The namespace is usually ingress-nginx, checking for controller pod
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=150s

# --- INSTALL ARGO CD ---
Write-Host "Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Enable Helm in Kustomize for Argo CD
Write-Host "Patching Argo CD to enable Helm support in Kustomize..."
# NOTE: Using 'data' key for merge patch
kubectl -n argocd patch cm argocd-cm --type merge -p "{\`"data\`":{\`"kustomize.buildOptions\`":\`"--enable-helm\`"}}"

# Wait for Argo CD
Write-Host "Waiting for Argo CD Server..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# --- DEPLOY PLATFORM APPS ---
Write-Host "Deploying Platform Components (Backstage, Vault, Observability)..."
kubectl apply -f platform/applications.yaml

# Get Initial Password
$argocdPwd = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# --- BACKGROUND PORT FORWARDING ---
Write-Host "Starting Port-Forwards in Background Jobs..."

# Function to start a port-forward job
function Start-PortForward {
    param (
        [string]$Name,
        [string]$Namespace,
        [string]$Service,
        [string]$Ports
    )
    Write-Host " - Forwarding $Name ($Service) on $Ports"
    # Starting as a process so it persists if simple jobs fail or to be explicit
    # Using Start-Process with -WindowStyle Minimized to keep them out of the way but running
    Start-Process kubectl -ArgumentList "port-forward svc/$Service -n $Namespace $Ports" -WindowStyle Minimized
}

Start-PortForward -Name "ArgoCD" -Namespace "argocd" -Service "argocd-server" -Ports "8080:443"
Start-PortForward -Name "Backstage" -Namespace "backstage" -Service "backstage" -Ports "7007:7007"
Start-PortForward -Name "Grafana" -Namespace "observability" -Service "prometheus-grafana" -Ports "3000:80"


Write-Host "---------------------------------------------------"
Write-Host "Cluster Bootstrapped Successfully!"
Write-Host "All services have been port-forwarded in background windows."
Write-Host ""
Write-Host "1. Argo CD:       https://localhost:8080"
Write-Host "   Login:         admin"
Write-Host "   Password:      $argocdPwd"
Write-Host ""
Write-Host "2. Backstage:     http://localhost:7007"
Write-Host ""
Write-Host "3. Grafana:       http://localhost:3000"
Write-Host "   User:          admin"
Write-Host "   Password:      (See 'prom-grafana' secret if needed)"
Write-Host "---------------------------------------------------"
