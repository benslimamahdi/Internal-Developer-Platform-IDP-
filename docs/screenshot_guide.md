# 📸 Portfolio Screenshot Guide

To make this project "Resume-Ready", we need to visually demonstrate that the platform is real and functional. Please verify the platform is running (see README) and then capture the following screenshots.

**Save all images to the `docs/img/` directory.** (Create the directory if it doesn't exist).

## 1. Argo CD Dashboard (The "Control Plane")
*   **Goal**: Show that the "App-of-Apps" pattern is working and all platform components are healthy.
*   **Action**: 
    1. Open URL: `https://localhost:8080` (or your forwarded port).
    2. Login (admin / password from bootstrap output).
    3. Collapse the "Applications" view to show `vault`, `backstage`, `policies`, `observability` all synced and Green 💚.
*   **Save as**: `docs/img/argocd-dashboard.png`

## 2. Backstage Scaffolder (The "Golden Path")
*   **Goal**: Show the developer experience for creating new services.
*   **Action**:
    1. Open URL: `http://localhost:7007`.
    2. Navigate to "Create" (left sidebar).
    3. Take a screenshot of the available templates (e.g., "React Frontend").
*   **Save as**: `docs/img/backstage-templates.png`

## 3. Backstage Catalog (The "Inventory")
*   **Goal**: Show that services are registered and visible.
*   **Action**:
    1. Navigate to "Home" or "Catalog".
    2. Show the list of registered components (even if just the sample ones).
*   **Save as**: `docs/img/backstage-catalog.png`

## 4. Policy Enforcement (The "Guardrails")
*   **Goal**: Prove that Kyverno is actively blocking bad deployments.
*   **Action**:
    1. Run this command in your terminal: `kubectl run priv-pod --image=nginx --privileged`
    2. Take a screenshot of the **Error Message** output (e.g., `Error from server: admission webhook... denied...`).
*   **Save as**: `docs/img/policy-denial.png`

## 5. Grafana Dashboards (The "Observability")
*   **Goal**: Show that metrics are being collected.
*   **Action**:
    1. Open URL: `http://localhost:3000`.
    2. Navigate to **Dashboards** -> **Kubernetes / Compute Resources / Namespace (Pods)**.
    3. Show some graphs with data.
*   **Save as**: `docs/img/grafana-metrics.png`
