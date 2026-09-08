release.yaml
    └── Build → Push → Capture Digest → Store Release Metadata

staging.yaml
    └── Get Release → Deploy Digest → Rollout → Smoke → Integration → DAST

production.yaml
    └── Get Release → Approval → Retag Digest → Release History → Deploy Digest → Rollout



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

    ├── verify deployed digest
    └── record release history
