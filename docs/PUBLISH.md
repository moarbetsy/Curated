# Publish to GitHub (bootstrap-ready)

After you push this repo to GitHub, anyone can bootstrap with the one-liner (replace `<OWNER>` and `<REPO>` with your GitHub org/repo).

## 1. Create the repo on GitHub

- Go to [GitHub New Repository](https://github.com/new).
- Create a repo (e.g. `Curated`). Prefer **empty** (no README, no .gitignore) so you push existing content.
- Note the URL: `https://github.com/<OWNER>/<REPO>.git`.

## 2. Init and push (if not already a git repo)

From the Curated folder (repo root):

```powershell
git init
git add .
git commit -m "Bootstrap-ready: scripts, curated.ps1, docs"
git branch -M main
git remote add origin https://github.com/<OWNER>/<REPO>.git
git push -u origin main
```

If the repo is already initialized and you only need to push:

```powershell
git remote add origin https://github.com/<OWNER>/<REPO>.git
git push -u origin main
```

Use `git remote -v` to see existing remotes; use `git push -u origin main` to set upstream.

## 3. Bootstrap one-liner (for your users)

After push, the default branch should be `main`. Then this one-liner works (replace `<OWNER>` and `<REPO>`):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/<OWNER>/<REPO>/main/scripts/bootstrap.ps1' -OutFile \"$env:TEMP\bootstrap.ps1\" -UseBasicParsing; & pwsh -NoProfile -ExecutionPolicy Bypass -File \"$env:TEMP\bootstrap.ps1\" -RepoUrl 'https://github.com/<OWNER>/<REPO>' -Ref main"
```

If your default branch is not `main`, use `-Ref <branch>` in the script and in the URL path (e.g. `.../master/scripts/bootstrap.ps1` and `-Ref master`).
