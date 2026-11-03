#!/bin/bash
# Double-click me: builds Island.app, quits any running copy, and launches it.
cd "$(dirname "$0")"
echo "== Building Island in $(pwd) =="
if ./make-app.sh; then
  echo "== Launching =="
  pkill -x Island 2>/dev/null
  sleep 0.5
  open Island.app
  echo "Done. Hover or click the notch, or press fn+W once Accessibility access is granted."
else
  echo "== BUILD FAILED (see errors above) =="
fi
