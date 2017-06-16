# Add human readable sizes.
alias ll='ls -alFh'

# Look up the weather at a given location.
# All credit goes to https://github.com/chubin/wttr.in
#
# Example:
#  weather Mountain View
#  weather 94040
weather() { curl "wttr.in/~$*"; }

# Display our external facing ip.
# All credit goes to https://major.io
alias myip="curl icanhazip.com"

# Once more, with feeling!
# Rerun the previous command, prepended with sudo.
alias plz="fc -l -1 | cut -d' ' -f2- | xargs sudo"
