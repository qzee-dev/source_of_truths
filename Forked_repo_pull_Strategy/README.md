You should add a new section covering the complete contribution process after creating your feature branch. This will take the documentation beyond fork synchronization and explain how to:

1. Create a new file in your forked repository.
2. Add content to the file.
3. Move changes into Git staging.
4. Commit staged changes.
5. Push the feature branch to your GitHub fork.
6. Create a Pull Request from your fork's feature branch into the original organization's `develop` branch.
7. Respond to code reviews and CI/CD checks.

The important distinction is that you push your feature branch to `origin`, but your Pull Request targets `upstream/develop`.

Here is the complete updated Markdown document, including the new feature development, staging, commit, push, and upstream Pull Request workflow.

# 🔄 Forking, Syncing Your Fork, and Contributing to Upstream Repositories

When contributing to an organization repository where you only have read access, you can fork the repository, synchronize your fork with upstream, create a feature branch, make changes, and submit a Pull Request (PR) to the original repository.

---

## 📌 1. Why Sync Your Fork First?

Suppose the upstream repository has received new commits:

**Upstream Repository**

```
upstream/develop

A --- B --- C --- D --- E
```

**Your Fork**

```
origin/develop

A --- B --- C
```

If you start working immediately:

```
A --- B --- C --- X --- Y
```

Your branch is now missing the upstream commits:

```
D
E
```

This can lead to:

- ❌ Merge conflicts.
- ❌ Failing CI/CD pipelines.
- ❌ Outdated code.
- ❌ Unexpected test failures.

---

## 🚀 2. Recommended Workflow

### Step 1: Update Your Local Branch

First, switch to your local `develop` branch and fetch the latest changes from upstream.

```
git checkout develop
git fetch upstream
git merge upstream/develop
```

Alternatively:

```
git pull upstream develop
```

### Step 2: Push the Updated Branch to Your Fork

After successfully merging the upstream changes, push the updated branch to your personal fork.

```
git push origin develop
```

This ensures your fork contains the latest changes from the upstream repository.

### Step 3: Create a Feature Branch

Once your fork is synchronized, create a feature branch for your work.

**Using checkout:**

```
git checkout -b feature/my-feature
```

**Or using the modern switch command:**

```
git switch -c feature/my-feature
```

You can now start working on your changes without modifying the `develop` branch directly.

---

## 🔗 3. Understanding Git Remotes

When working with a fork, you typically have two Git remotes:

- **`origin`** – Your personal fork.
- **`upstream`** – The original repository you forked from.

### Example Repository Structure

```
upstream
company-org/fintech-platform
        |
        v
origin
qzee-dev/fintech-platform
```

### Check Your Configured Remotes

Run:

```
git remote -v
```

**Example Output:**

```
origin    git@github.com:qzee-dev/fintech-platform.git (fetch)
origin    git@github.com:qzee-dev/fintech-platform.git (push)

upstream  git@github.com:company-org/fintech-platform.git (fetch)
upstream  git@github.com:company-org/fintech-platform.git (push)
```

### Add the Upstream Remote

If the upstream remote is not configured, add it:

```
git remote add upstream git@github.com:company-org/fintech-platform.git
```

> **Note:** Replace the URL with the actual upstream repository URL.

Verify:

```
git remote -v
```

---

## 📂 4. Create a New File in Your Feature Branch

After creating your feature branch, you can start developing new features or modifying existing files.

**Important:** Always confirm that you are working on your feature branch before creating or modifying files.

### Step 1: Confirm Your Current Branch

```
git branch
```

Example output:

```
  develop
* feature/my-feature
  main
```

The asterisk (`*`) indicates your current working branch.

You can also run:

```
git branch --show-current
```

Expected output:

```
feature/my-feature
```

### Step 2: Create a New File

For example, create a Markdown documentation file:

```
touch docs/FORKING-AND-SYNCING.md
```

If the `docs` directory does not exist, create it first:

```
mkdir -p docs
touch docs/FORKING-AND-SYNCING.md
```

You can also create a new file using VS Code:

```
code docs/FORKING-AND-SYNCING.md
```

Add your documentation or code to the newly created file and save it.

### Step 3: Check Your Changes

Run:

```
git status
```

Example output:

```
On branch feature/my-feature

Untracked files:
  docs/FORKING-AND-SYNCING.md

nothing added to commit but untracked files present
```

Git recognizes the new file, but it has not yet been added to the staging area.

---

## 📦 5. Move Changes into the Git Staging Area

Before committing your changes, you must stage them.

### Step 1: Stage a Specific File

To add only the new documentation file:

```
git add docs/FORKING-AND-SYNCING.md
```

Alternatively, stage all modified and newly created files:

```
git add .
```

> **Best Practice:** Use `git add <filename>` when you want precise control over which files are included in a commit.

### Step 2: Verify Staged Changes

Run:

```
git status
```

Example output:

```
On branch feature/my-feature

Changes to be committed:
  new file: docs/FORKING-AND-SYNCING.md
```

Your file is now in the **staging area**.

### Understanding Git Staging

Git follows three important stages before changes become part of your repository history:

```
Working Directory
       |
       | git add
       v
Staging Area
       |
       | git commit
       v
Local Repository
       |
       | git push
       v
Remote Repository (origin)
```

| Stage             | Description                                        |
| ----------------- | -------------------------------------------------- |
| Working Directory | Where you create or modify files.                  |
| Staging Area      | Where you prepare changes for a commit.            |
| Local Repository  | Where committed changes are stored locally.        |
| Remote Repository | Where your committed changes are pushed to GitHub. |

---

## 💾 6. Commit Your Staged Changes

Once your changes are staged, create a commit.

Run:

```
git commit -m "docs: add fork synchronization guide"
```

**Understanding the command:**

- `git commit` – Saves staged changes into your local Git history.
- `-m` – Specifies the commit message.
- `docs:` – Indicates that the commit contains documentation changes.

### Verify Your Commit

Run:

```
git log --oneline -5
```

Example output:

```
a1b2c3d docs: add fork synchronization guide
```

You can also check:

```
git status
```

Expected output:

```
On branch feature/my-feature
nothing to commit, working tree clean
```

Your changes are now committed locally but have not yet been pushed to GitHub.

---

## ☁️ 7. Push Your Feature Branch to Your Fork

After committing your changes, push your feature branch to your personal GitHub repository.

Run:

```
git push -u origin feature/my-feature
```

**Understanding the command:**

- `git push` – Uploads your local commits to GitHub.
- `-u` – Sets the upstream tracking relationship for the branch.
- `origin` – Your personal fork.
- `feature/my-feature` – The feature branch you are pushing.

Example:

```
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Writing objects: 100% (5/5), done.

To github.com:qzee-dev/fintech-platform.git
 * [new branch] feature/my-feature -> feature/my-feature

branch 'feature/my-feature' set up to track
'origin/feature/my-feature'.
```

Your feature branch is now available on your personal GitHub fork.

---

## 🔀 8. Create a Pull Request to the Upstream Develop Branch

After pushing your feature branch, the next step is to submit a Pull Request to the original organization's repository.

**Important:** Your Pull Request must originate from your fork and target the upstream repository.

### Step 1: Open Your Fork on GitHub

Navigate to your personal fork:

```
https://github.com/qzee-dev/fintech-platform
```

Select your newly pushed feature branch:

```
feature/my-feature
```

GitHub may display a notification:

**Compare & pull request**

Click it to begin creating your Pull Request.

### Step 2: Configure the Pull Request

On the Pull Request page, configure the repositories and branches as follows:

**Base Repository (Upstream):**

```
company-org/fintech-platform
```

**Base Branch:**

```
develop
```

**Head Repository (Your Fork):**

```
qzee-dev/fintech-platform
```

**Compare Branch:**

```
feature/my-feature
```

Your Pull Request should look like this:

```
BASE REPOSITORY
company-org/fintech-platform
             |
             v
BASE BRANCH
develop
             ^
             |
HEAD BRANCH
feature/my-feature
             |
             ^
             |
HEAD REPOSITORY
qzee-dev/fintech-platform
```

### Step 3: Add a Pull Request Title and Description

Example:

**Title:**

```
docs: add fork synchronization guide
```

**Description:**

```
## Summary

- Added documentation explaining how to fork repositories.
- Documented how to configure upstream remotes.
- Added instructions for synchronizing forks.
- Documented feature branch creation and contribution workflow.

## Changes

- Added `docs/FORKING-AND-SYNCING.md`.

## Testing

- Verified Git commands and documentation structure.
- Confirmed changes are committed and pushed to the feature branch.
```

### Step 4: Submit the Pull Request

Click:

**Create pull request**

Your Pull Request is now submitted to the original organization's `develop` branch.

> **Note:** Creating a Pull Request does not automatically merge your changes. The upstream maintainers must review and approve it according to their repository policies.

---

## 🔍 9. Code Review and CI/CD Checks

After creating your Pull Request, the upstream repository may automatically trigger CI/CD workflows.

Typical checks include:

- GitHub Actions CI workflows.
- Unit and integration tests.
- Linting and code formatting.
- Type checking.
- SonarQube code analysis.
- Trivy security scanning.
- Dependency vulnerability scanning.
- Branch protection and required status checks.

### Possible Pull Request Outcomes

| Status            | Meaning                                          |
| ----------------- | ------------------------------------------------ |
| Checks Passed     | Automated validation completed successfully.     |
| Checks Failed     | One or more CI/CD checks require attention.      |
| Changes Requested | A reviewer has requested modifications.          |
| Approved          | A reviewer has approved your changes.            |
| Merged            | Your changes have been integrated into upstream. |

### If Changes Are Requested

Make the necessary modifications in your existing feature branch.

```
git add .
git commit -m "fix: address pull request review comments"
git push origin feature/my-feature
```

GitHub automatically updates the existing Pull Request when you push additional commits to the same branch.

You do not need to create another Pull Request.

---

## 🔄 10. Sync Your Fork Again After Your Pull Request Is Merged

Once your Pull Request has been merged into the upstream `develop` branch, synchronize your fork again.

First, switch to your local `develop` branch:

```
git checkout develop
```

Fetch the latest upstream changes:

```
git fetch upstream
```

Merge the latest upstream `develop` branch:

```
git merge upstream/develop
```

Push the updated branch to your fork:

```
git push origin develop
```

You can now create another feature branch for your next contribution.

```
git switch -c feature/next-feature
```

---

## 📊 11. Complete GitHub Fork Contribution Workflow

The complete workflow from forking to merging looks like this:

```
              FORK UPSTREAM REPOSITORY
                        |
                        v
              CONFIGURE UPSTREAM REMOTE
                        |
                        v
                SYNC YOUR FORK
                        |
                        v
               UPDATE LOCAL DEVELOP
                        |
                        v
               CREATE FEATURE BRANCH
                        |
                        v
                CREATE NEW FILE
                        |
                        v
               MODIFY / ADD CONTENT
                        |
                        v
                  GIT ADD
                        |
                        v
                STAGING AREA
                        |
                        v
                 GIT COMMIT
                        |
                        v
                LOCAL REPOSITORY
                        |
                        v
                  GIT PUSH
                        |
                        v
                 YOUR GITHUB FORK
                        |
                        v
                CREATE PULL REQUEST
                        |
                        v
          TARGET UPSTREAM DEVELOP BRANCH
                        |
                        v
              CODE REVIEW AND CI/CD
                        |
                        v
             APPROVAL AND MERGE
                        |
                        v
                SYNC YOUR FORK
                        |
                        v
             READY FOR NEXT CONTRIBUTION
```

---

## 💡 12. Recommendation and Best Practices

When contributing to an organization's repository through a fork:

1. Always synchronize your fork before starting new work.
2. Never develop directly on your local `develop` or `main` branch.
3. Create a separate feature branch for each contribution.
4. Review your changes using `git status` and `git diff` before staging.
5. Stage only the files you intend to commit.
6. Use meaningful commit messages.
7. Push feature branches to your personal fork (`origin`).
8. Submit Pull Requests against the appropriate upstream branch (`develop` or `main`).
9. Address review comments in the same feature branch.
10. Synchronize your fork after upstream changes are merged.

---

## 🎯 Key Takeaway

**Remember the difference between `origin` and `upstream`:**

- `origin` is where you push your feature branches.
- `upstream` is where the original organization's repository lives.
- Your Pull Request sends changes from your fork's feature branch into the upstream repository's target branch.

**The typical contribution process is:**

```
# 1. Synchronize your fork
git fetch upstream
git checkout develop
git merge upstream/develop
git push origin develop

# 2. Create a feature branch
git switch -c feature/my-feature

# 3. Create and modify files
touch docs/FORKING-AND-SYNCING.md

# 4. Stage your changes
git add docs/FORKING-AND-SYNCING.md

# 5. Commit your changes
git commit -m "docs: add fork synchronization guide"

# 6. Push your feature branch to your fork
git push -u origin feature/my-feature

# 7. Create a Pull Request on GitHub
# Head: qzee-dev:feature/my-feature
# Base: company-org:develop
```

**This workflow provides a clean, controlled, and collaborative approach to contributing to organization repositories through GitHub forks and Pull Requests.**

Recommended location in your repository:

```
fintech-platform/
├── docs/
│   ├── FORKING-AND-SYNCING.md
│   └── CONTRIBUTING.md
├── .github/
├── services/
├── libs/
└── README.md
```

This is a useful contribution guide to keep in your fintech-platform repository, especially when collaborating with other developers through GitHub forks, protected branches, and CI/CD pipelines.
