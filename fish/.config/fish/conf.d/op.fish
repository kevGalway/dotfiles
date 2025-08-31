# Prefer desktop unlock for CLI
set -gx OP_BIOMETRIC_UNLOCK_ENABLED true

# Helper: ensure op is unlocked (no-op if already unlocked)
function op-unlock
    if not command -q op
        echo "op CLI not installed"
        return 1
    end
    op whoami >/dev/null 2>&1; and return 0
    # This will trigger the desktop unlock prompt
    op signin >/dev/null 2>&1
end
