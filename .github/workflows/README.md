
 # Release, Promotion and Rollback Strategy

 This repository uses a **build-once, promote-by-digest** deployment strategy.

 The release process is divided into four independent GitHub Actions workflows:

```
release.yaml
    └── Build → Push → Capture Digest → Store Release Metadata

staging.yaml
    └── Get Release → Validate → Deploy Digest → Rollout → Smoke → Integration → DAST

production.yaml
    └── Get Release → Validate → Approval → Retag Digest → Deploy Digest → Rollout → Release History

rollback.yaml
    └── Select Known-Good Release → Verify Digest → Approval → Deploy Digest → Verify → Record Rollback
```

 The fundamental rule is:

 > **Build once. Test the exact artifact. Approve it. Promote the exact same immutable digest. Roll back to a previously known-good immutable digest.**

---

 # Architecture

```
                         release.yaml
                              │
                              ▼
                       SELECT SERVICE
                              │
                              ▼
                       SELECT VERSION
                              │
                              ▼
                        CHECKOUT CODE
                              │
                              ▼
                         BUILD IMAGE
                              │
                              ▼
                          PUSH ECR
                              │
                              ▼
                     CAPTURE ECR DIGEST
                              │
                              ▼
                  STORE RELEASE METADATA
                              │
                              ▼
                       RELEASE ARTIFACT
                              │
                              ▼
                        staging.yaml
                              │
                              ▼
                    VALIDATE RELEASE
                              │
                              ▼
                     VERIFY ECR DIGEST
                              │
                              ▼
                    DEPLOY SAME DIGEST
                              │
                              ▼
                    VERIFY ROLLOUT
                              │
                              ▼
                       SMOKE TESTS
                              │
                              ▼
                    INTEGRATION TESTS
                              │
                              ▼
                            DAST
                              │
                              ▼
                       STAGING PASS
                              │
                              ▼
                      production.yaml
                              │
                              ▼
                    VALIDATE SAME RELEASE
                              │
                              ▼
                      VERIFY DIGEST
                              │
                              ▼
                    PRODUCTION APPROVAL
                              │
                              ▼
                     RETAG SAME DIGEST
                              │
                              ▼
                    DEPLOY SAME DIGEST
                              │
                              ▼
                    VERIFY ROLLOUT
                              │
                              ▼
                  STORE RELEASE HISTORY
                              │
                              ▼
                         PRODUCTION
                              │
                     ┌────────┴────────┐
                     │                 │
                  HEALTHY           FAILURE
                     │                 │
                     │                 ▼
                     │          rollback.yaml
                     │                 │
                     │                 ▼
                     │        SELECT KNOWN-GOOD
                     │             RELEASE
                     │                 │
                     │                 ▼
                     │          VERIFY DIGEST
                     │                 │
                     │                 ▼
                     │        PRODUCTION APPROVAL
                     │                 │
                     │                 ▼
                     │        DEPLOY SAME DIGEST
                     │                 │
                     └────────────◄────┘
```

---

 # Workflow Separation

 The workflows remain intentionally separated.

```
.github/workflows/

├── release.yaml
├── staging.yaml
├── production.yaml
└── rollback.yaml
```

 Each workflow has a specific responsibility.

---

 # 1\. `release.yaml`

 `release.yaml` is responsible for creating a release artifact.

```
release.yaml
    │
    ├── Select service
    ├── Select version
    ├── Checkout source
    ├── Validate version
    ├── Capture commit
    ├── Generate build tag
    ├── Build Docker image
    ├── Push image to ECR
    ├── Capture immutable digest
    ├── Verify digest
    └── Store release metadata
```

 The engineer manually selects the service and version.

 Example:

```
Service:
payment-service

Version:
v1.3.5
```

 The workflow generates:

```
Commit:
a7d39bc

Build Tag:
v1.3.5-a7d39bc

Release ID:
payment-service-v1.3.5-a7d39bc

Immutable Digest:
sha256:6c41f3f5....
```

---

 # Release Identity

 Every release must maintain the following identity:

```
Service:
payment-service

Human Version:
v1.3.5

Commit:
a7d39bc

Build Tag:
v1.3.5-a7d39bc

Immutable Digest:
sha256:6c41f3f5....

Release ID:
payment-service-v1.3.5-a7d39bc

Release Run ID:
123456789
```

 The relationship is:

```
payment-service
       │
       ▼
v1.3.5
       │
       ▼
v1.3.5-a7d39bc
       │
       ▼
sha256:6c41f3f5....
```

 The **digest is the source of truth**.

 The semantic version and build tag are human-readable identifiers.

---

 # Release Artifact

 `release.yaml` stores the release metadata as an artifact.

 Recommended metadata:

```
release-data/
├── service.txt
├── version.txt
├── commit.txt
├── image-tag.txt
├── digest.txt
├── release-id.txt
└── release-run-id.txt
```

 Example:

```
service.txt
payment-service

version.txt
v1.3.5

commit.txt
a7d39bc123456789...

image-tag.txt
v1.3.5-a7d39bc

digest.txt
sha256:6c41f3f5....

release-id.txt
payment-service-v1.3.5-a7d39bc

release-run-id.txt
123456789
```

---

 # 2\. `staging.yaml`

 `staging.yaml` consumes the exact release produced by `release.yaml`.

```
staging.yaml
    │
    ├── Get release
    ├── Validate release identity
    ├── Verify ECR digest
    ├── Deploy digest
    ├── Verify rollout
    ├── Verify deployed digest
    ├── Smoke tests
    ├── Integration tests
    └── DAST
```

 The staging workflow must not rebuild the Docker image.

 It deploys:

```
payment-service@sha256:6c41f3f5....
```

---

 # Cross-Workflow Release Handoff

 The release workflow produces:

```
release_run_id
release_id
service
version
commit
image_tag
digest
```

 The handoff is:

```
release.yaml
     │
     ├── release_id
     │     payment-service-v1.3.5-a7d39bc
     │
     ├── release_run_id
     │     123456789
     │
     └── digest
           sha256:6c41f3f5...
                    │
                    ▼
             staging.yaml
                    │
                    ├── same release_run_id
                    ├── same release_id
                    ├── same service
                    ├── same version
                    └── same digest
                    │
                    ▼
             Download release artifact
                    │
                    ▼
             Verify ECR digest
                    │
                    ▼
             Deploy digest
                    │
                    ▼
             Smoke / Integration / DAST
                    │
                    ▼
                 STAGING PASS
                    │
                    ▼
             production.yaml
                    │
                    ├── same release_run_id
                    ├── same release_id
                    ├── same version
                    └── same digest
                           │
                           ▼
                    Production Approval
                           │
                           ▼
                    Deploy same digest
```

---

 # 3\. `production.yaml`

 Production promotes the exact artifact that passed staging.

```
production.yaml
    │
    ├── Get release
    ├── Validate same release
    ├── Verify same digest
    ├── GitHub production approval
    ├── Create human-readable ECR tag
    ├── Verify production tag
    ├── Deploy same digest
    ├── Verify rollout
    ├── Verify deployed digest
    └── Store release history
```

 Production does not rebuild the image.

 Production deploys:

```
payment-service@sha256:6c41f3f5....
```

 The same digest that passed staging.

---

 # Production Approval

 Production must use a GitHub Environment:

```
production
```

 with required reviewers configured.

 The deployment flow becomes:

```
STAGING PASS
     │
     ▼
production.yaml
     │
     ▼
GitHub Production Environment
     │
     ▼
Required Reviewer Approval
     │
     ▼
Production Deployment
```

 The approval is a deployment gate.

---

 # ECR Tagging

 After staging passes and production is approved, the same digest can receive the human-readable production tag.

 Before promotion:

```
payment-service:v1.3.5-a7d39bc
              │
              ▼
       sha256:6c41f3f5....
```

 After production promotion:

```
payment-service:v1.3.5-a7d39bc
payment-service:v1.3.5
              │
              ▼
       sha256:6c41f3f5....
```

 Both tags point to the same immutable digest.

 No rebuild occurs.

---

 # 4\. Automatic Production Release History

 Release history is created automatically by `production.yaml`.

 It does **not** need to be manually created for every release.

 The repository uses:

```
release-history/
└── <service>/
    ├── v1.3.3.json
    ├── v1.3.4.json
    ├── v1.3.5.json
    └── ...
```

 Example:

```
release-history/
└── payment-service/
    ├── v1.3.4.json
    └── v1.3.5.json
```

 The workflow creates these files after a successful production deployment.

 Example:

```
{
  "release_id": "payment-service-v1.3.5-a7d39bc",
  "release_run_id": "123456789",
  "service": "payment-service",
  "version": "v1.3.5",
  "image_tag": "v1.3.5-a7d39bc",
  "digest": "sha256:6c41f3f5....",
  "commit": "a7d39bc123456789...",
  "environment": "production",
  "approved_by": "github-user",
  "production_workflow_run_id": "987654321",
  "deployed_at": "2026-09-08T00:00:00Z"
}
```

 The release history therefore records the complete production identity.

---

 # Release History Purpose

 Release history provides the relationship between:

```
Service
   │
   ├── Version
   ├── Release ID
   ├── Release Run ID
   ├── Commit
   ├── Build Tag
   ├── ECR Digest
   ├── Production Workflow
   └── Production Deployment
```

 This information is used by `rollback.yaml`.

---

 # 5\. `rollback.yaml`

 Rollback is a separate workflow.

```
rollback.yaml
    │
    ├── Select service
    ├── Select rollback type
    ├── Find known-good release
    ├── Read release history
    ├── Verify ECR digest
    ├── Verify build tag
    ├── Prevent no-op rollback
    ├── GitHub production approval
    ├── Deploy immutable digest
    ├── Verify rollout
    ├── Verify deployed digest
    └── Record rollback
```

 Rollback does not rebuild the application.

 Rollback does not create a new Docker image.

 Rollback restores a previously known-good immutable digest.

---

 # Rollback Options

 Rollback supports two modes.

 ## Previous Production Release

 The engineer selects:

```
Service:
payment-service

Rollback Type:
previous
```

 The workflow determines the current production digest.

 Example:

```
Current:

v1.3.5
sha256:CCC
```

 Release history contains:

```
v1.3.4 → sha256:BBB
v1.3.5 → sha256:CCC
```

 The workflow selects:

```
v1.3.4
sha256:BBB
```

---

 ## Specific Known-Good Version

 The engineer can explicitly select:

```
Service:
payment-service

Rollback Type:
specific

Target Version:
v1.3.4
```

 The workflow reads:

```
release-history/payment-service/v1.3.4.json
```

 It obtains:

```
Version:
v1.3.4

Digest:
sha256:BBB
```

 It verifies the digest still exists in ECR before deploying it.

---

 # Rollback Flow

```
Current Production
       │
       ▼
v1.3.5
sha256:CCC
       │
       │ INCIDENT
       ▼
rollback.yaml
       │
       ▼
Find Known-Good Release
       │
       ▼
v1.3.4
sha256:BBB
       │
       ▼
Verify ECR Digest
       │
       ▼
Production Approval
       │
       ▼
Deploy
       │
       ▼
Verify Rollout
       │
       ▼
Verify Deployed Digest
       │
       ▼
Production
v1.3.4
sha256:BBB
```

---

 # Rollback Is Not a Rebuild

 The rollback process must never do this:

```
Old Commit
    │
    ▼
Docker Build
    │
    ▼
New Image
    │
    ▼
Production
```

 Instead:

```
Known-Good Release
       │
       ▼
Existing ECR Digest
       │
       ▼
Production
```

 This guarantees that rollback uses the exact image that was previously built and deployed.

---

 # Rollback Verification

 Before rollback:

```
Current Production Digest
        │
        ▼
Target Release Digest
```

 The target digest must:

 - Exist in ECR.
- Match the release history.
- Match the build tag.
- Belong to the requested service.
- Represent a valid release.
- Not already be the currently deployed digest.

 After deployment, Kubernetes is checked again.

 Expected:

```
ECR:

payment-service@sha256:BBB

Kubernetes:

payment-service@sha256:BBB
```

 If they do not match, the rollback fails.

---

 # Rollback History

 Every rollback is also recorded.

```
release-history/
└── payment-service/
    ├── v1.3.4.json
    ├── v1.3.5.json
    │
    └── rollbacks/
        └── 123456789.json
```

 Example:

```
{
  "type": "rollback",
  "service": "payment-service",
  "restored_version": "v1.3.4",
  "restored_digest": "sha256:BBB",
  "restored_image_tag": "v1.3.4-a6f21bc",
  "restored_commit": "a6f21bc123456789...",
  "release_id": "payment-service-v1.3.4-a6f21bc",
  "release_run_id": "111111111",
  "rollback_workflow_run_id": "123456789",
  "rollback_type": "previous",
  "requested_by": "github-user",
  "rolled_back_at": "2026-09-08T00:00:00Z"
}
```

 This provides an audit trail for the rollback itself.

---

 # Complete ECR Lifecycle

 Example release:

```
payment-service:v1.3.5-a7d39bc
              │
              ▼
       sha256:6c41f3f5....
```

 After production:

```
payment-service:v1.3.5-a7d39bc ──┐
                                 ├── sha256:6c41f3f5....
payment-service:v1.3.5 ──────────┘
```

 Previous release:

```
payment-service:v1.3.4-a6f21bc
payment-service:v1.3.4
              │
              ▼
       sha256:previous....
```

 If rollback is required:

```
Production
v1.3.5
sha256:6c41f3f5....
       │
       ▼
rollback.yaml
       │
       ▼
v1.3.4
sha256:previous....
```

 No image is rebuilt.

---

 # Source of Truth

 The architecture intentionally distinguishes between human-readable identifiers and immutable identity.

```
Human Version
     │
     ▼
v1.3.5

Build Tag
     │
     ▼
v1.3.5-a7d39bc

Immutable Digest
     │
     ▼
sha256:6c41f3f5....
```

 The source of truth is:

```
sha256:6c41f3f5....
```

 Not:

```
v1.3.5
```

 Not:

```
v1.3.5-a7d39bc
```

 The tags are labels.

 The digest identifies the actual artifact.

---

 # Repository Structure

 The recommended repository structure is:

```
.github/
└── workflows/
    ├── release.yaml
    ├── staging.yaml
    ├── production.yaml
    └── rollback.yaml

helm/
├── Chart.yaml
├── values.yaml
└── templates/

services/
├── api-gateway/
├── user-service/
├── payment-service/
├── wallet-service/
├── transaction-service/
├── notification-service/
└── fraud-service/

tests/
├── smoke.sh
├── integration.sh
└── dast.sh

release-history/
├── payment-service/
│   ├── v1.3.4.json
│   ├── v1.3.5.json
│   └── rollbacks/
│
├── wallet-service/
│   └── ...
│
└── user-service/
    └── ...
```

---

 # Release Lifecycle

```
                         BUILD
                           │
                           ▼
                    PUSH TO ECR
                           │
                           ▼
                  CAPTURE DIGEST
                           │
                           ▼
                  RELEASE METADATA
                           │
                           ▼
                        STAGING
                           │
              ┌────────────┴────────────┐
              │                         │
           FAILURE                    PASS
              │                         │
              ▼                         ▼
            STOP                  PRODUCTION
                                        │
                                        ▼
                                   APPROVAL
                                        │
                                        ▼
                                   PRODUCTION
                                        │
                              ┌─────────┴─────────┐
                              │                   │
                           HEALTHY             FAILURE
                              │                   │
                              │                   ▼
                              │              ROLLBACK
                              │                   │
                              │                   ▼
                              │            KNOWN-GOOD
                              │              DIGEST
                              │                   │
                              │                   ▼
                              │              APPROVAL
                              │                   │
                              │                   ▼
                              └──────────────► PRODUCTION
```

---

 # Deployment Guarantees

 This architecture provides:

 - Build once.
- Deploy many.
- Immutable ECR digest.
- No rebuild after staging.
- Same artifact from staging to production.
- Manual release selection.
- Manual production approval.
- Service-level releases.
- Release traceability.
- Commit traceability.
- ECR digest traceability.
- Staging test gates.
- Production deployment verification.
- Automatic production release history.
- Auditable rollback.
- Rollback to a known-good digest.
- No rollback rebuild.
- Cross-workflow release identity.

---

 # Operational Rules

 The following rules should be treated as non-negotiable:

```
1. Never rebuild for production promotion.

2. Never rebuild during rollback.

3. Always deploy using the immutable digest.

4. Always verify the digest exists in ECR.

5. Always verify the deployed Kubernetes image digest.

6. Production requires GitHub Environment approval.

7. Release history is generated automatically after successful production deployment.

8. Rollback uses release history to identify a known-good digest.

9. Every rollback is recorded.

10. The ECR digest is the source of truth.
```

---

 # Final Model

```
                     ONE BUILD
                         │
                         ▼
                  ONE RELEASE ID
                         │
                         ▼
                  ONE ECR DIGEST
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
           STAGING              RELEASE HISTORY
              │                     │
              ▼                     │
        TEST / DAST                 │
              │                     │
              ▼                     │
         STAGING PASS               │
              │                     │
              ▼                     │
         PRODUCTION                 │
              │                     │
              ▼                     │
           APPROVAL                 │
              │                     │
              ▼                     │
       SAME ECR DIGEST              │
              │                     │
              ▼                     │
         PRODUCTION                │
              │                     │
        ┌─────┴─────┐              │
        │           │              │
     HEALTHY      FAILURE          │
        │           │              │
        │           ▼              │
        │       ROLLBACK ◄─────────┘
        │           │
        │           ▼
        │    KNOWN-GOOD DIGEST
        │           │
        │           ▼
        │      APPROVAL
        │           │
        │           ▼
        └──────► PRODUCTION
```

 ## Core Principle

 > **Build once. Capture the immutable digest. Test that exact digest in staging. Require production approval. Deploy the same digest to production. If production fails, restore a previously known-good digest without rebuilding. Automatically record both releases and rollbacks for auditability.**

 This is now the version I'd keep as the **master README** for the architecture. The only remaining implementation work is to make the four YAML workflows conform exactly to this README—especially the `release_id`/`release_run_id` handoff and automatic `release-history` generation.
