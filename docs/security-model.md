# Security Model

The IDP enforces a **Shared Responsibility Model** but offloads most of the burden to the platform via "Secure by Default" guardrails.

## 1. Governance & Policy (Kyverno)
We use [Kyverno](https://kyverno.io) to enforce policy at the Kubernetes admission layer.

### Enforced Policies
*   **`disallow-privileged-containers`**: Applications cannot run as root or with `privileged: true`.
*   **`restrict-image-registries`**: Images can only be pulled from approved registries (e.g., GHCR, Quay, Docker Hub).
*   **`require-labels`**: All Pods must have a `team` label for cost attribution.

**Developer Experience:**
If a developer tries to deploy a non-compliant manifest, the deployment is **rejected**, and the error message explains specifically *why* (e.g., "RunAsUser must be 1000+").

## 2. Secrets Management (Vault)
*   **No Hardcoded Secrets**: Secrets are never checked into Git.
*   **Injection**: We use the Vault Sidecar Injector or External Secrets Operator to inject secrets at runtime.
*   **Rotation**: Vault handles automatic rotation of ephemeral credentials (e.g., DB passwords).

## 3. Network Security
*   **Ingress**: All external traffic flows through an Nginx Ingress Controller with TLS termination.
*   **Network Policies**: (Planned) Default deny-all policies for namespaces, requiring explicit allow-lists for service-to-service communication.

## 4. Supply Chain Security
*   **CI/CD**: All builds happen in ephemeral CI runners.
*   **Scanning**: (Planned) Trivy integration in the build pipeline to scan Docker images for CVEs before pushing.
