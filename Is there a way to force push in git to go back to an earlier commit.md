---
created: 2024-09-03T14:02
updated: 2024-09-03T14:04
---
# Is there a way to force push in git to go back to an earlier commit

Yes, it is possible to force push in Git to go back to an earlier commit. Here are the steps:

1. First, you need to check out the commit that you want to revert back to. Let's assume that the hash of this commit is `abc123`. You can do this by running:
   ```
   git checkout abc123
   ```

2. Now, create a new branch at this commit:
   ```
   git checkout -b new-branch
   ```

3. Switch back to the branch where you want this older commit (let's assume this branch is `master`):
   ```
   git checkout master
   ```

4. Reset this branch to the new one (which points at the older commit) using the `--hard` option:
   ```
   git reset --hard new-branch
   ```

5. Finally, force push this change to your remote repository (let's assume it is named `origin`):
    ```
    git push origin master --force
    ```

Be careful though, as force pushing can overwrite changes in your remote repository and can be destructive if not used correctly.

Remember that each time you use force push, you should notify all other collaborators immediately so they can update their local repositories accordingly.

Also consider using `git push --force-with-lease` instead of `git push --force`, as it will refuse to update a branch unless it is the state that we expect; i.e., nobody has pushed new commits up while we were working on our changes.
