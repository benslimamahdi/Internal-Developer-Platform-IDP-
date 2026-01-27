# Platform Architecture

## Executive Summary
This Internal Developer Platform (IDP) is designed to provide a "Golden Path" to production for engineering teams. It abstracts infrastructure complexity while enforcing security, governance, and operability standards through a GitOps-based workflow.

## high-Level Architecture Diagram

```mermaid
graph TD
    subgraph Developer_Experience ["Developer Experience Layer"]
        Dev[Developer]
        Backstage[Backstage Portal]
        Git[Git Repository (GitHub/GitLab)]
    end

    subgraph Control_Plane ["Control Plane (Platform Cluster)"]
        ArgoCD[Argo CD (GitOps Controller)]
        Vault[HashiCorp Vault (Secrets)]
        Kyverno[Kyverno (Policy Engine)]
        Prom[Prometheus/Grafana (Observability)]
    end

    subgraph Workload_Plane ["Workload Plane (App Cluster/NS)"]
        App_Dev[Dev Environment]
        App_Staging[Staging Environment]
        App_Prod[Production Environment]
    end

    Dev -->| scaffolds app | Backstage
    Backstage -->| commits code + manifests | Git
    ArgoCD -->| watches | Git
    ArgoCD -->| deploys/syncs | App_Dev
    ArgoCD -->| deploys/syncs | App_Staging
    ArgoCD -->| deploys/syncs | App_Prod

    App_Dev -.->| fetches secrets | Vault
    App_Dev -.->| validated by | Kyverno
    App_Dev -.->| metrics | Prom
```

## Component Breakdown

### 1. Developer Portal (Backstage)
*   **Role:** Single pane of glass for developers.
*   **Function:**
    *   **Scaffolding:** Creates new services from "Golden Templates" (Backend, Frontend, Worker).
    *   **Catalog:** Central directory of all microservices, libraries, and resources.
    *   **Docs-like-code:** Aggregates technical documentation.
*   **Decision:** Chose Backstage as it is the CNCF standard for developer portals, offering extensibility and a rich ecosystem.

### 2. GitOps Engine (Argo CD)
*   **Role:** Continuous Delivery and Infrastructure State Manager.
*   **Function:**
    *   Synchronizes Kubernetes state with Git repositories.
    *   Detects configuration drift.
    *   Provides a dashboard for application health and sync status.
*   **Pattern:** "App-of-Apps" pattern to manage the platform components and user workloads hierarchically.

### 3. Secrets Management (HashiCorp Vault)
*   **Role:** Centralized Secret Store.
*   **Function:**
    *   Stores API keys, database credentials, and certificates.
    *   Injects secrets into pods via Kubernetes Auth Method and/or CSI Driver.
    *   Handles secret rotation.
*   **Decision:** Vault is the industry standard for enterprise secret management, superior to K8s native secrets for security and auditing.

### 4. Governance & Policy (Kyverno)
*   **Role:** Policy Enforcement Point.
*   **Function:**
    *   Validates manifests against security rules (e.g., prevent root containers).
    *   Mutates resources (e.g., adding default labels or sidecars).
    *   Generates configuration (e.g., default NetworkPolicies).
*   **Decision:** Kyverno chosen over OPA Gatekeeper for its Kubernetes-native policy syntax (YAML), reducing the cognitive load of Rego.

### 5. Observability (Prometheus + Grafana)
*   **Role:** Monitoring and Alerting.
*   **Function:**
    *   **Prometheus:** Scrapes metrics from platform and application workloads.
    *   **Grafana:** Visualizes metrics with pre-built dashboards for platform health (Argo, K8s) and application signals (RED method).

## Operational Workflows

### 1. New Service Creation
1. Developer logs into **Backstage**.
2. Selects a template (e.g., "Go Backend Service").
3. Files details (Name, Owner, Tier).
4. Backstage scaffolds repo, CI pipelines, and Helm charts.
5. Backstage registers the component in the Catalog.

### 2. Deployment Flow
1. Developer merges PR to `main` branch.
2. CI builds Docker image and pushes to Registry.
3. CI updates the `helm` chart version in the GitOps config repo.
4. **Argo CD** detects the change and syncs the new version to the `dev` environment.

### 3. Policy Enforcement
1. Argo CD attempts to apply a manifest (e.g., a Pod running as root).
2. API Server intercepts request + sends to **Kyverno**.
3. Kyverno validates against `ClusterPolicy`.
4. If violation: Request Denied + Error displayed in Argo CD UI.
