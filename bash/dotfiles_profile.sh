# Machine-local install level, chosen once by setup_dotfiles.sh (see the
# PROFILE selection there) and saved to ~/.dotfiles_profile. Consulted by
# alias.sh and bindings.sh to skip features that are fine on your own
# machine but unwelcome on an account shared with other people.
export DOTFILES_PROFILE="$(cat "$HOME/.dotfiles_profile" 2>/dev/null || echo personal)"
