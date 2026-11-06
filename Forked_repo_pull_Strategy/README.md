# Forking and Keeping Your Fork Up to Date

When contributing to a repository where you only have **read access**, it is recommended to keep your fork synchronized with the upstream repository before starting new work.

## Why Sync Your Fork First?

Suppose the upstream repository has received new commits:

```text
upstream/develop

A --- B --- C --- D --- E
```

Your fork was created earlier:

```text
origin/develop

A --- B --- C
```

If you start working immediately:

```text
A --- B --- C --- X --- Y
```

Your branch is now missing:

```text
D
E
```

This can lead to:

- Merge conflicts
- Failing CI/CD pipelines
- Outdated code
- Unexpected test failures

---

## Recommended Workflow

### 1. Update Your Local Branch

```bash
git checkout develop
git fetch upstream
git merge upstream/develop
```

Or:

```bash
git pull
