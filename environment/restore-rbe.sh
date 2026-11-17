#!/usr/bin/env bash
ROM="${1:-$HOME/evo}"
TOOLS="$HOME/tools/android-buildbuddy-rbe-main"
FIX="$ROM/prebuilts/remoteexecution-client/buildbuddyfix"
cd "$ROM" || exit 1
if grep -q buildbuddyfix build/make/core/rbe.mk 2>/dev/null; then
  echo ">>> patch already in"
else
  patch -p1 --forward < "$TOOLS/patches/android-rbe-buildbuddyfix-defaults.patch"
  find build -name '*.rej' -delete; find build -name '*.orig' -delete
fi
if [ ! -x "$FIX/rewrapper" ]; then
  if [ -x "$HOME/.rbe/reclient-fix/rewrapper" ]; then
    mkdir -p "$FIX" && cp -a "$HOME/.rbe/reclient-fix/." "$FIX/"
  else
    bash "$TOOLS/scripts/build_patched_reclient.sh" "$ROM"
    cp -a "$FIX" "$HOME/.rbe/reclient-fix"
  fi
fi
cp "$HOME/.rbe/rbe_env.sh" "$ROM/rbe_env.sh" && chmod 600 "$ROM/rbe_env.sh"
echo ">>> done"
