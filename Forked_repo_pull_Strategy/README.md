# 🔄 Forking and Keeping Your Fork Up to Date

When contributing to a repository where you only have read access, it is recommended to keep your fork synchronized with the upstream repository before starting new work.

---

## 📌 Why Sync Your Fork First?

Suppose the upstream repository has received new commits:

**Upstream Repository**

```text
upstream/develop

A --- B --- C --- D --- E
```

**Your Fork**

```text
origin/develop

A --- B --- C
```

If you start working immediately:

```text
A --- B --- C --- X --- Y
```

Your branch is now missing the upstream commits:

```text
D
E
```

This can lead to:

- ❌ Merge conflicts.
- ❌ Failing CI/CD pipelines.
- ❌ Outdated code.
- ❌ Unexpected test failures.

---

## 🚀 Recommended Workflow

### 1. Update Your Local Branch

First, switch to your local `develop` branch and fetch the latest changes from upstream.

```bash
git checkout develop
git fetch upstream
git merge upstream/develop
```

Alternatively, you can use:

```bash
git pull upstream develop
```

### 2. Push the Updated Branch to Your Fork

After successfully merging the upstream changes, push the updated branch to your personal fork.

```bash
git push origin develop
```

This ensures your fork contains the latest changes from the upstream repository.

### 3. Create a Feature Branch

Once your fork is synchronized, create a feature branch for your work.

**Using `checkout`:**

```bash
git checkout -b feature/my-feature
```

**Or using the modern `switch` command:**

```bash
git switch -c feature/my-feature
```

You can now start working on your changes using the latest codebase.

---

## 🔗 Understanding Git Remotes

When working with a fork, you typically have two Git remotes:

- **`origin`** – Your personal fork.
- **`upstream`** – The original repository you forked from.

### Example Repository Structure

```text
upstream
company-org/fintech-platform
        |
        v
origin
qzee-dev/fintech-platform
```

### Check Your Configured Remotes

To see the remotes configured in your local repository, run:

```bash
git remote -v
```

**Example Output:**

```text
origin    git@github.com:qzee-dev/fintech-platform.git (fetch)
origin    git@github.com:qzee-dev/fintech-platform.git (push)

upstream  git@github.com:company-org/fintech-platform.git (fetch)
upstream  git@github.com:company-org/fintech-platform.git (push)
```

### Add the Upstream Remote

If the upstream remote is not configured, add it using:

```bash
git remote add upstream git@github.com:company-org/fintech-platform.git
```

> **Note:** Replace the URL with the actual upstream repository URL.

Verify the configuration:

```bash
git remote -v
```

---

## 🔄 Syncing Your Fork

Whenever you want to synchronize your fork with the upstream repository, run:

```bash
git fetch upstream
git checkout develop
git merge upstream/develop
git push origin develop
```

### Understanding the Commands

| Command | Description |
|---|---|
| `git fetch upstream` | Retrieves the latest upstream changes without modifying your local branches. |
| `git checkout develop` | Switches to your local develop branch. |
| `git merge upstream/develop` | Merges upstream changes into your local develop branch. |
| `git push origin develop` | Pushes the synchronized branch to your personal fork. |

---

## ❓ Is Syncing Mandatory?

**No.** GitHub allows you to fork a repository, create a branch, make changes, and open a Pull Request without synchronizing first.

However, syncing is strongly recommended when:

- The repository is actively maintained.
- Multiple developers are contributing.
- CI/CD pipelines are enforced.
- Branch protection rules are enabled.
- You are targeting `develop` or `main`.

---

## 📊 Typical Contribution Workflow

```text
          Fork Repository
                 |
                 v
      Configure Upstream Remote
                 |
                 v
       Sync Fork with Upstream
                 |
                 v
        Create Feature Branch
                 |
                 v
          Develop Changes
                 |
                 v
         Push to Your Fork
                 |
                 v
          Create Pull Request
                 |
                 v
      Code Review and CI/CD Checks
                 |
                 v
          Merge into Upstream
```

---

## 💡 Recommendation

If you only have read access to an organization's repository, make it a habit to synchronize your fork with the upstream repository before starting new work.

This helps to:

- Reduce merge conflicts.
- Keep your codebase up to date.
- Avoid unexpected integration issues.
- Improve the likelihood of your Pull Requests passing CI/CD checks successfully.

---

## 🎯 Key Takeaway

**Always synchronize your fork before creating a new feature branch.**

This keeps your development environment aligned with the latest upstream changes and supports a cleaner, more reliable GitHub contribution workflow.
