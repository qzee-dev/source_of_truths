release.yaml
    └── Build → Push → Capture Digest → Store Release Metadata

staging.yaml
    └── Get Release → Deploy Digest → Rollout → Smoke → Integration → DAST

production.yaml
    └── Get Release → Approval → Retag Digest → Release History → Deploy Digest → Rollout
