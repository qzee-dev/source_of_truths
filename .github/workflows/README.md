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
    ├── verify deployed digest
    └── record release history
