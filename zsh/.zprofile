
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Disable macOS Terminal.app's shell session save/restore, which creates and
# populates ~/.zsh_sessions. Must be set before /etc/zshrc runs, so it lives
# here in .zprofile (login shells) rather than .zshrc. Apple's mechanism
# (/etc/zshrc_Apple_Terminal) honors this flag. Verified against that script.
export SHELL_SESSIONS_DISABLE=1
