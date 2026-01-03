#!/bin/bash
# Security Pre-commit Hook
# Scans for potential API keys before commit

echo "🔒 Running Security Scan..."

# Keywords to search for
FORBIDDEN_PATTERNS="(AIza|sk-proj-|EyJhbGci|supa_key|anon_key|service_role)"

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No files staged."
    exit 0
fi

FOUND_LEAK=0

# Scan each file
for FILE in $STAGED_FILES; do
    # Skip this script itself and lock files
    if [[ "$FILE" == *"run_security_scan.sh"* ]] || [[ "$FILE" == *".lock"* ]]; then
        continue
    fi
    
    # Grep for patterns
    MATCH=$(grep -E "$FORBIDDEN_PATTERNS" "$FILE")
    
    if [ ! -z "$MATCH" ]; then
        echo "❌ SECURITY ERROR: Potential Secret found in $FILE"
        echo "   Matched content: $MATCH"
        FOUND_LEAK=1
    fi
done

if [ $FOUND_LEAK -eq 1 ]; then
    echo "🚫 Commit Blocked. Please remove secrets before committing."
    echo "   Use 'git reset HEAD <file>' to unstage."
    exit 1
else
    echo "✅ Security Scan Passed."
    exit 0
fi
