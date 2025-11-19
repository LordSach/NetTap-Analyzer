#!/bin/bash
# ==========================================================
# Script to update Git commit author info for the current repo
# Replaces old commits with new name/email and optionally pushes
# ==========================================================

# --- Configuration ---
OLD_NAME="sachith-accelr"
OLD_EMAIL="sachith.rathnayake@accelr.site"
NEW_NAME="LordSach"
NEW_EMAIL="sachith.rathnayake.92@gmail.com"
BRANCH=$(git branch --show-current)

echo "Updating Git author info in branch: $BRANCH"
echo "Old author: $OLD_NAME <$OLD_EMAIL>"
echo "New author: $NEW_NAME <$NEW_EMAIL>"

# --- Backup branch ---
git branch backup-before-author-fix
echo "Backup branch created: backup-before-author-fix"

# --- Rewrite commits ---
git filter-branch --env-filter '
if [ "$GIT_COMMITTER_NAME" = "'"$OLD_NAME"'" ] || [ "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'" ]
then
    export GIT_COMMITTER_NAME="'"$NEW_NAME"'"
    export GIT_COMMITTER_EMAIL="'"$NEW_EMAIL"'"
fi
if [ "$GIT_AUTHOR_NAME" = "'"$OLD_NAME"'" ] || [ "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'" ]
then
    export GIT_AUTHOR_NAME="'"$NEW_NAME"'"
    export GIT_AUTHOR_EMAIL="'"$NEW_EMAIL"'"
fi
' --tag-name-filter cat -- --branches --tags

# --- Verify first 5 commits ---
echo "First 5 commits after update:"
git log --pretty=format:"%h %an <%ae>" | head -n 5

# --- Optional: force push to remote ---
read -p "Do you want to force push updated commits to remote? (y/n) " PUSH
if [ "$PUSH" = "y" ] || [ "$PUSH" = "Y" ]; then
    git push --force origin "$BRANCH"
    echo "Force pushed updated commits to remote!"
else
    echo "Skipped force push. You can push manually later."
fi

echo "Done! Old author info replaced."
