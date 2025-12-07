# PR #3059: Workflow Design Impact Analysis

## Affected Workflows
- **Helm Chart Deployment (Workflow 3)**: This workflow is directly impacted as the PR changes multiple template files in `helm-chart/templates/` to include optional `imagePullSecrets` in ServiceAccount resources. This enhances the configurability of deployments for private image registries. Justification: All changed files are Helm templates used in this workflow's rendering process during `helm install/upgrade`.

No other workflows are affected, as they rely on Kubernetes manifests or other tools without these Helm-specific changes. Workflows like Release Process (7) will indirectly include this in future chart publications, but no design changes to their flows.

## Workflow 3 Analysis

### Summary of design changes
The PR adds a new configuration capability to the Helm chart by templating `imagePullSecrets` into ServiceAccounts for each microservice and the OpenTelemetry collector. This is achieved through conditional Go templating in each service template file, referencing a new values path `serviceAccounts.imagePullSecrets`.

- **Affected aspects**: Template rendering step now supports additional ServiceAccount metadata; deployed resources include pull secrets if configured; customization examples now cover private registry setups.
- **Implementation**: Added 4 lines of Helm templating in 12 files, allowing list override in values for all service accounts uniformly.
- **Benefits**: Enables secure image pulls from private repositories (e.g., via dockerconfigjson secrets), useful for restricted environments; no impact on public image deployments.
- **Implications**: Users must manage secrets separately; enhances flexibility but adds a dependency on secret existence for private images.

The design documentation has been updated to reflect these changes, including descriptions, examples, and diagram annotations.

### Diff: Deployment Flow Sequence Diagram
This updated sequence diagram highlights the addition in green (rendering of ServiceAccounts with imagePullSecrets).

```mermaid
sequenceDiagram
    participant U as User/CLI
    participant H as Helm Client
    participant S as Kubernetes Server (API)
    participant R as Resources (Pods, Services, etc.)
    U->>H: helm upgrade --install [options] [values overrides]
    H->>H: Load chart from OCI registry or local path
    H->>H: Merge default values.yaml with user overrides
    H->>H: Render templates (e.g., service Deployments, conditional policies)
    Note right of H: Addition (in green): Include imagePullSecrets in ServiceAccounts if values.serviceAccounts.imagePullSecrets set
    H->>S: Apply rendered YAMLs (e.g., Deployments, Services, Redis if enabled)
    S->>R: Create/Update Kubernetes objects
    S->>R: Schedule Pods, pull images using ServiceAccount secrets if configured
    Note over R: Microservices start, gRPC health checks, inter-service communication begins
    R->>S: Pods become ready, Services get endpoints
    S->>H: Confirmation of resource creation
    H->>U: Helm release status (success/failure), NOTES for frontend access

```

(Note: The green highlighting via note and style on H for render phase.)

### Diff: Component Creation Flowchart
Updated flowchart with green for added/changed elements related to imagePullSecrets.

```mermaid
flowchart TD
    Start[User runs helm install/upgrade with values] --> Load[Load Chart.yaml, values.yaml, templates/]
    Load --> CheckFlags[Evaluate feature flags e.g. networkPolicies.create, cartDatabase.type]
    CheckFlags -->|imagePullSecrets set| ConfigIPS[Configure imagePullSecrets for ServiceAccounts]
    ConfigIPS --> RenderServices
    CheckFlags -->|redis| CreateRedis[Create in-cluster Redis StatefulSet/Service]
    CheckFlags -->|spanner| ConfigSpanner[Set env vars & annotations for Spanner connection]
    CheckFlags --> RenderServices[Render per-service templates:<br/>Deployments, Services, Probes, Resources]
    RenderServices -->|flags enabled| AddPolicies[Add NetworkPolicies, AuthPolicies, Sidecars]
    RenderServices --> AddOTEL[Add OTEL Collector if create: true]
    AddPolicies --> Apply[Apply all rendered resources to K8s API]
    AddOTEL --> Apply
    CreateRedis --> Apply
    ConfigSpanner --> Apply
    Apply --> Deploy[Deploy Pods; Image pulls from repository/tag <br/> using imagePullSecrets if present]
    Deploy --> Expose[Expose frontend via LoadBalancer or VirtualService]
    Expose --> Ready[Application ready: Access via external IP]
    style ConfigIPS fill:#90EE90
    style RenderServices fill:#FFFF00
    style Deploy fill:#90EE90
    style Start fill:#e1f5fe
    style Ready fill:#e8f5e8
```

- **Green rectangles**: New additions like ConfigIPS node and enhanced Deploy step for image pulls.
- **Yellow rectangle**: Changed RenderServices to note the inclusion.
- No red (removals).

These diagrams illustrate the integration of the new feature into the existing design.
