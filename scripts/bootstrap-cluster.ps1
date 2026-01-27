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

# Create Cluster
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

# Install Nginx Ingress Controller (Essential for accessing services)
Write-Host "Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress
Write-Host "Waiting for Ingress Controller..."
kubectl wait --namespace ingress-nginxStr --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Install Argo CD
Write-Host "Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD
Write-Host "Waiting for Argo CD Server..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Deploy Platform Applications (The "App of Apps")
Write-Host "Deploying Platform Components (Backstage, Vault, Observability)..."
kubectl apply -f platform/applications.yaml

# Get Initial Password
$argocdPwd = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

Write-Host "---------------------------------------------------"
Write-Host "Cluster Bootstrapped Successfully!"
Write-Host "Access Argo CD via Port Forwarding:"
Write-Host "kubectl port-forward svc/argocd-server -n argocd 8080:443"
Write-Host "Login: admin"
Write-Host "Password: $argocdPwd"
Write-Host ""
Write-Host "2. Backstage (Developer Portal):"
Write-Host "kubectl port-forward svc/backstage -n backstage 7007:7007"
Write-Host "URL: http://localhost:7007"
Write-Host ""
Write-Host "3. Grafana (Observability):"
Write-Host "kubectl port-forward svc/prometheus-grafana -n observability 3000:80"
Write-Host "URL: http://localhost:3000 (User: admin / Password: in secret 'prom-grafana')"
Write-Host "---------------------------------------------------"
