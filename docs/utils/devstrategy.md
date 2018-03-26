# CREATE PULL REQUEST AND MERGE STRATEGY



## Fork upstream and clone your fork.
git clone https://GITHUB/USER/REPO.git
cd REPO
git remote add upstream https://GITHUB/UPSTREAM-OWNER/REPO.git
git remote -v

## Work on pull request in a new topic branch.
git checkout -b TOPIC-BRANCH
git add FILES
git commit
git push origin TOPIC-BRANCH

## Go to your fork on GitHub, switch to the topic branch, and
## click *Compare & pull request*.

---
After the pull request merged.

## Keep your fork's main development branch updated with upstream's.
git fetch upstream
git checkout master
git merge upstream/master
git push origin master

## Delete topic branch branch after pull request is merged.
git checkout master
git branch -D TOPIC-BRANCH
git push -d origin TOPIC-BRANCH
