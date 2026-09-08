Absolutely. Since you want this as a **GitHub-ready, editable `README.md`**, here is the complete Markdown content. I kept your flow and wording intact, while formatting it so it renders cleanly on GitHub.

 README.md — Release Promotion Flow

# Release Promotion Flow

 This repository uses a **build-once, promote-by-digest** release strategy.

 The release process is divided into three independent GitHub Actions workflows:

```
release.yaml
    └── Build → Push → Capture Digest → Store Release Metadata

staging.yaml
    └── Get Release → Deploy Digest → Rollout → Smoke → Integration → DAST

production.yaml
    └── Get Release → Approval → Retag Digest → Release History → Deploy Digest → Rollout
```

---

 ## Release Flow

```
release.yaml
    │
    ├── service
    ├── version
    ├── commit
    ├── build tag
    ├── immutable digest
    └── release ID
          │
          ▼
staging.yaml
    │
    ├── validate release
    ├── verify ECR digest
    ├── deploy digest
    ├── rollout
    ├── smoke
    ├── integration
    └── DAST
          │
          ▼
     STAGING PASS
          │
          ▼
production.yaml
    │
    ├── validate same release
    ├── verify same digest
    ├── GitHub production approval
    ├── create v1.3.5 ECR tag
    ├── deploy same digest
    ├── verify rollout
    ├── verify deployed digest
    └── record release history
```

---

 ## Release Artifact Identity

 The release is identified using multiple pieces of metadata.

 The **immutable ECR digest is the source of truth**.

```
Service:
payment-service

Human Version:
v1.3.5

Commit:
a7d39bc...

Build Tag:
v1.3.5-a7d39bc

Immutable Digest:
sha256:6c41f3f5....

Release ID:
payment-service-v1.3.5-a7d39bc
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

 The digest represents the exact container image that was built and tested.

---

 # `release.yaml`

 The release workflow is responsible for building and publishing the selected service.

```
release.yaml
    │
    ├── Select service
    │
    ├── Select release version
    │
    ├── Checkout source
    │
    ├── Validate version
    │
    ├── Validate service
    │
    ├── Capture commit
    │
    ├── Generate build tag
    │
    ├── Build Docker image
    │
    ├── Push image to ECR
    │
    ├── Capture immutable ECR digest
    │
    ├── Verify digest
    │
    └── Store release metadata
```

 The resulting release metadata contains:

```
service
version
commit
image_tag
digest
release_id
release_run_id
```

 Example:

```
Service:
payment-service

Version:
v1.3.5

Commit:
a7d39bc123456789...

Build Tag:
v1.3.5-a7d39bc

Digest:
sha256:6c41f3f5....

Release ID:
payment-service-v1.3.5-a7d39bc

Release Run ID:
123456789
```

---

 # `staging.yaml`

 The staging workflow retrieves the exact release created by `release.yaml`.

```
staging.yaml
    │
    ├── Get Release
    │
    ├── Validate release identity
    │
    ├── Verify source commit
    │
    ├── Verify ECR digest
    │
    ├── Verify build tag
    │
    ├── Deploy exact digest
    │
    ├── Verify rollout
    │
    ├── Verify deployed digest
    │
    ├── Smoke tests
    │
    ├── Integration tests
    │
    └── DAST
```

 The staging workflow does **not rebuild the Docker image**.

 It deploys the exact digest produced by `release.yaml`.

```
payment-service@sha256:6c41f3f5....
```

---

 # Staging Validation

 Before deployment, staging validates:

```
release_id
    +
release_run_id
    +
service
    +
version
    +
commit
    +
build tag
    +
digest
```

 The ECR digest is then verified.

```
Expected:

sha256:6c41f3f5....

        │
        ▼

ECR

        │
        ▼

sha256:6c41f3f5....

        │
        ▼

MATCH
```

 Only after the digest is verified does the workflow deploy to Kubernetes.

---

 # Staging Tests

 After deployment:

```
Deploy
  │
  ▼
Rollout Verification
  │
  ▼
Smoke Tests
  │
  ▼
Integration Tests
  │
  ▼
DAST
  │
  ▼
STAGING PASS
```

 All required checks must pass before the release is considered ready for production.

---

 # `production.yaml`

 The production workflow promotes the same release that passed staging.

```
production.yaml
    │
    ├── Get Release
    │
    ├── Validate same release
    │
    ├── Verify same digest
    │
    ├── Verify build tag
    │
    ├── GitHub production approval
    │
    ├── Create human-readable production tag
    │
    ├── Verify production tag
    │
    ├── Deploy same digest
    │
    ├── Verify rollout
    │
    ├── Verify deployed digest
    │
    └── Record release history
```

 Production does **not rebuild the Docker image**.

 Production deploys:

```
payment-service@sha256:6c41f3f5....
```

 The same digest that was tested in staging.

---

 # Cross-Workflow Release Handoff

 The release workflow produces a specific workflow run ID.

 Example:

```
release_run_id:
123456789
```

 The release also produces:

```
release_id:
payment-service-v1.3.5-a7d39bc
```

 And:

```
digest:
sha256:6c41f3f5....
```

 The complete handoff is:

```
release.yaml
     │
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
                    ├── release_run_id = 123456789
                    ├── release_id
                    └── service
                    │
                    ▼
             Download artifact
             FROM RUN 123456789
                    │
                    ▼
             Validate release
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
                 STAGING
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
                    Production approval
                           │
                           ▼
                    Deploy same digest
```

---

 # Build Once, Promote Same Digest

 The fundamental rule of the release process is:

```
                BUILD
                  │
                  ▼
             Docker Image
                  │
                  ▼
                 ECR
                  │
                  ▼
          Immutable Digest
                  │
          ┌───────┴───────┐
          │               │
          ▼               ▼
       STAGING        PRODUCTION
          │               │
          ▼               │
        TESTS             │
          │               │
          ▼               │
       APPROVAL ──────────┘
                  │
                  ▼
            SAME DIGEST
```

 There is:

```
NO REBUILD
```

 between staging and production.

 There is:

```
NO SECOND DOCKER BUILD
```

 during production deployment.

 There is:

```
NO DIFFERENT IMAGE
```

 between environments.

---

 # Digest Is the Source of Truth

 The human version:

```
v1.3.5
```

 is used for human-readable release identification.

 The build tag:

```
v1.3.5-a7d39bc
```

 identifies the build.

 The immutable digest:

```
sha256:6c41f3f5....
```

 identifies the actual container image.

 Therefore:

```
Human Version
     │
     ▼
Build Tag
     │
     ▼
Immutable Digest
     │
     ├───────────────┐
     ▼               ▼
  STAGING        PRODUCTION
```

 The digest is the authoritative identity.

---

 # ECR Example

 After `release.yaml`:

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

 Both tags point to the **same immutable digest**.

 No image rebuild occurs.

---

 # Release History

 Production records the release in:

```
release-history/
└── payment-service-v1.3.5.json
```

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
  "environment": "production"
}
```

 This provides an auditable relationship between:

```
Service
   │
   ├── Version
   ├── Commit
   ├── Build
   ├── ECR Digest
   ├── Staging
   └── Production
```

---

 # Complete Release Lifecycle

```
                         ┌─────────────────┐
                         │   release.yaml  │
                         └────────┬────────┘
                                  │
                                  ▼
                           Select Service
                                  │
                                  ▼
                           Select Version
                                  │
                                  ▼
                            Checkout Code
                                  │
                                  ▼
                             Build Image
                                  │
                                  ▼
                             Push ECR
                                  │
                                  ▼
                         Capture ECR Digest
                                  │
                                  ▼
                       Store Release Metadata
                                  │
                                  ▼
                         Release Run Created
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  staging.yaml   │
                         └────────┬────────┘
                                  │
                                  ▼
                       Download Exact Release
                                  │
                                  ▼
                        Validate Release ID
                                  │
                                  ▼
                      Validate Release Run ID
                                  │
                                  ▼
                        Verify ECR Digest
                                  │
                                  ▼
                         Deploy Exact Digest
                                  │
                                  ▼
                         Verify Rollout
                                  │
                                  ▼
                           Smoke Tests
                                  │
                                  ▼
                        Integration Tests
                                  │
                                  ▼
                              DAST
                                  │
                                  ▼
                         ┌───────────────┐
                         │ STAGING PASS  │
                         └───────┬───────┘
                                 │
                                 ▼
                       ┌──────────────────┐
                       │ production.yaml  │
                       └────────┬─────────┘
                                │
                                ▼
                      Get Exact Release
                                │
                                ▼
                    Validate Same Release
                                │
                                ▼
                    Verify Same Digest
                                │
                                ▼
                    GitHub Approval
                                │
                                ▼
                    Retag Same Digest
                                │
                                ▼
                    Deploy Same Digest
                                │
                                ▼
                    Verify Rollout
                                │
                                ▼
                  Verify Deployed Digest
                                │
                                ▼
                   Record Release History
                                │
                                ▼
                         PRODUCTION
```

---

 # Core Release Guarantees

 This release architecture guarantees:

 - **Build once**
- **Deploy many**
- **Immutable ECR digest**
- **No rebuild after staging**
- **Same artifact from staging to production**
- **Manual release selection**
- **Manual production approval**
- **Service-level releases**
- **Release traceability**
- **Commit traceability**
- **ECR digest traceability**
- **Staging test gates**
- **Production deployment verification**
- **Release history**
- **Cross-workflow release identity**

 The final principle is:

```
                ONE BUILD
                   │
                   ▼
              ONE DIGEST
                   │
          ┌────────┴────────┐
          ▼                 ▼
       STAGING          PRODUCTION
          │                 │
          ▼                 ▼
        TEST                RUN
          │                 │
          └───────┬─────────┘
                  ▼
            SAME DIGEST
```

 **Build once. Test the exact artifact. Approve it. Promote the exact same digest.**

 You can paste that directly into the repository as `README.md`.
