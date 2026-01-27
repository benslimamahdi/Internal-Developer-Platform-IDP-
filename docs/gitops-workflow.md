# GitOps Workflow

This platform uses **Argo CD** as the single source of truth for the cluster state.

## The "App-of-Apps" Pattern
We use a hierarchical structure:
1.  **Platform Root App**: Manages the core platform services (Backstage, Observability, etc.).
2.  **User Apps**: Managed individually or via a similar parent "Team Root App".

## Workflow for Developers

### 1. Day 1: Scaffolding
*   Developer uses Backstage to create a new service.
*   Backstage creates a repo with a `manifests/` directory.

### 2. Day 2: Changing Configuration
*   **Scenario**: Need to increase memory limits.
*   **Action**: Developer opens a Pull Request to `manifests/deployment.yaml`.
*   **Review**: Team lead reviews the PR.
*   **Merge**: PR is merged to `main`.
*   **Sync**: Argo CD detects the change (within 3 mins) and applies it to the cluster.

### 3. Deploying New Code
*   **Action**: Developer merges code to `main`.
*   **CI**: GitHub Actions builds the image `myapp:sha-123`.
*   **Update**: The CI pipeline updates `manifests/deployment.yaml` to use `image: myapp:sha-123`.
*   **Sync**: Argo CD deploys the new image.

## Drift Detection
If someone manually changes a resource (e.g., `kubectl edit`), Argo CD detects the **Drift** and marks the app as "OutOfSync".
*   **Self-Heal**: In Production, we enable `selfHeal` to immediately revert manual changes.
