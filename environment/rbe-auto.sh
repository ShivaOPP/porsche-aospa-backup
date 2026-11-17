# rbe-auto.sh  --  source this file; do not execute it.
#   rbe_auto                   find ROM, check key, patch, set env
#   rbe_build <lunch> [goal]   rbe_auto + lunch + build + RBE stats check
# State lives in ~/.rbe (keys, saved ROM path, reclient backup).

RBE_HOME="$HOME/.rbe"
RBE_TOOLS_REPO="https://github.com/aditya-arch-7/android-buildbuddy-rbe.git"

_rbe_say()  { printf '\033[1;36m>>>\033[0m %s\n' "$*"; }
_rbe_warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*"; }
_rbe_err()  { printf '\033[1;31mXXX\033[0m %s\n' "$*"; }

# ---------- ROM detection ----------
_rbe_is_rom() {
  [ -n "$1" ] && [ -d "$1" ] && [ -e "$1/build/envsetup.sh" ] &&
  { [ -d "$1/.repo" ] || [ -d "$1/build/soong" ]; }
}

_rbe_find_rom() {
  local d
  # 1. argument
  if [ -n "$1" ]; then
    d="$(cd "$1" 2>/dev/null && pwd)"
    _rbe_is_rom "$d" && { echo "$d"; return 0; }
  fi
  # 2. already lunched shell
  _rbe_is_rom "$ANDROID_BUILD_TOP" && { echo "$ANDROID_BUILD_TOP"; return 0; }
  # 3. current dir or a parent
  d="$PWD"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    _rbe_is_rom "$d" && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  # 4. saved path
  if [ -f "$RBE_HOME/rom_dir" ]; then
    d="$(cat "$RBE_HOME/rom_dir")"
    _rbe_is_rom "$d" && { echo "$d"; return 0; }
  fi
  # 5. scan common places for .repo folders
  local found=() p
  while IFS= read -r p; do
    d="$(dirname "$p")"
    _rbe_is_rom "$d" && found+=("$d")
  done < <(timeout 25 find "$HOME" /mnt /data /opt /home -maxdepth 3 -type d -name .repo 2>/dev/null | sort -u)
  if [ "${#found[@]}" -eq 1 ]; then
    echo "${found[0]}"; return 0
  elif [ "${#found[@]}" -gt 1 ]; then
    _rbe_say "More than one ROM found:" >&2
    local i=1
    for d in "${found[@]}"; do echo "  $i) $d" >&2; i=$((i+1)); done
    local n
    read -r -p "Pick number (or type a path): " n
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#found[@]}" ]; then
      echo "${found[$((n-1))]}"; return 0
    fi
    d="$(cd "${n/#\~/$HOME}" 2>/dev/null && pwd)"
    _rbe_is_rom "$d" && { echo "$d"; return 0; }
  fi
  # 6. ask
  local tries=0
  while [ "$tries" -lt 3 ]; do
    read -r -p "Could not find a ROM. Enter ROM source directory: " d
    d="$(cd "${d/#\~/$HOME}" 2>/dev/null && pwd)"
    _rbe_is_rom "$d" && { echo "$d"; return 0; }
    _rbe_warn "Not a ROM tree (need build/envsetup.sh and .repo)." >&2
    tries=$((tries+1))
  done
  return 1
}

# ---------- key handling ----------
_rbe_clean() {
  printf '%s' "$1" | sed 's/\x1b\[20[01]~//g' | tr -cd 'A-Za-z0-9'
}

# return 0 ok, 1 rejected, 2 no network, 3 unknown answer
_rbe_key_check() {
  local k="$1" out code body
  out="$(mktemp)"
  code="$(curl -s -m 25 -o "$out" -w '%{http_code}' -X POST \
    https://app.buildbuddy.io/api/v1/GetInvocation \
    -H "x-buildbuddy-api-key: $k" -H 'Content-Type: application/json' \
    -d '{"selector":{"invocation_id":"keycheck"}}' 2>/dev/null)"
  body="$(head -c 400 "$out" 2>/dev/null)"; rm -f "$out"
  case "$code" in
    000) return 2 ;;
    401|403) return 1 ;;
  esac
  if printf '%s' "$body" | grep -qiE 'unauthenticated|invalid.*key|permission'; then return 1; fi
  [ "$code" = "200" ] && return 0
  return 3
}

_rbe_load_key() {
  local n k rc
  mkdir -p "$RBE_HOME"; chmod 700 "$RBE_HOME"
  for n in 1 2; do
    [ -f "$RBE_HOME/acc$n.key" ] || continue
    k="$(sed -n 's/^export BUILDBUDDY_API_KEY="\(.*\)"$/\1/p' "$RBE_HOME/acc$n.key" | head -1)"
    k="$(_rbe_clean "$k")"
    [ -n "$k" ] || continue
    _rbe_key_check "$k"; rc=$?
    case $rc in
      0) _rbe_say "Key from account $n is OK."; export BUILDBUDDY_API_KEY="$k"; RBE_ACTIVE_ACCOUNT=$n; return 0 ;;
      2) _rbe_warn "No network to BuildBuddy. Cannot check key. Using account $n anyway."
         export BUILDBUDDY_API_KEY="$k"; RBE_ACTIVE_ACCOUNT=$n; return 0 ;;
      3) _rbe_warn "Key check gave an unclear answer. Using account $n anyway."
         export BUILDBUDDY_API_KEY="$k"; RBE_ACTIVE_ACCOUNT=$n; return 0 ;;
      1) _rbe_warn "Key from account $n was REJECTED." ;;
    esac
  done
  # nothing good: ask
  local tries=0
  while [ "$tries" -lt 3 ]; do
    read -r -s -p "Enter BuildBuddy API key (hidden, paste once): " k; echo
    k="$(_rbe_clean "$k")"
    if [ "${#k}" -ne 20 ]; then
      _rbe_warn "Key length is ${#k}, expected 20. Check you pasted it once."
      tries=$((tries+1)); continue
    fi
    _rbe_key_check "$k"; rc=$?
    if [ $rc -eq 0 ] || [ $rc -eq 2 ] || [ $rc -eq 3 ]; then
      printf 'export BUILDBUDDY_API_KEY="%s"\n' "$k" > "$RBE_HOME/acc1.key"
      chmod 600 "$RBE_HOME/acc1.key"
      export BUILDBUDDY_API_KEY="$k"; RBE_ACTIVE_ACCOUNT=1
      _rbe_say "Key saved to $RBE_HOME/acc1.key"
      return 0
    fi
    _rbe_warn "BuildBuddy rejected that key."
    tries=$((tries+1))
  done
  return 1
}

# ---------- tools, patch, reclient ----------
_rbe_find_tools() {
  local d
  for d in "$RBE_TOOLS" "$HOME/tools/android-buildbuddy-rbe-main" "$HOME/android-buildbuddy-rbe" \
           "/mnt/data/tools/android-buildbuddy-rbe-main"; do
    [ -n "$d" ] && [ -f "$d/patches/android-rbe-buildbuddyfix-defaults.patch" ] && { echo "$d"; return 0; }
  done
  mkdir -p "$HOME/tools"
  _rbe_say "Tools repo not found, cloning..." >&2
  git clone --depth=1 "$RBE_TOOLS_REPO" "$HOME/tools/android-buildbuddy-rbe-main" >&2 2>&1 || return 1
  echo "$HOME/tools/android-buildbuddy-rbe-main"
}

_rbe_patch() {
  local rom="$1" tools="$2" p="$2/patches/android-rbe-buildbuddyfix-defaults.patch"
  if grep -q buildbuddyfix "$rom/build/make/core/rbe.mk" 2>/dev/null &&
     grep -q buildbuddyfix "$rom/build/soong/remoteexec/remoteexec.go" 2>/dev/null; then
    _rbe_say "Patch already in tree."; return 0
  fi
  _rbe_say "Applying BuildBuddy patch..."
  if ! ( cd "$rom" && patch -p1 --forward --dry-run < "$p" >/dev/null 2>&1 ); then
    _rbe_err "Patch does not apply cleanly to this ROM (maybe a new Android version)."
    ( cd "$rom" && patch -p1 --forward --dry-run < "$p" 2>&1 | tail -15 )
    _rbe_err "Paste the lines above to get a fix."
    return 1
  fi
  ( cd "$rom" && patch -p1 --forward < "$p" ) || return 1
  find "$rom/build" \( -name '*.rej' -o -name '*.orig' \) -delete 2>/dev/null
  return 0
}

_rbe_reclient() {
  local rom="$1" tools="$2" fix="$1/prebuilts/remoteexecution-client/buildbuddyfix"
  if [ -x "$fix/rewrapper" ] && [ -x "$fix/reproxy" ]; then
    _rbe_say "Patched reclient present."
  elif [ -x "$RBE_HOME/reclient-fix/rewrapper" ]; then
    _rbe_say "Restoring patched reclient from backup..."
    mkdir -p "$fix" && cp -a "$RBE_HOME/reclient-fix/." "$fix/" || return 1
  else
    _rbe_say "Building patched reclient (needs net + Go from the ROM)..."
    bash "$tools/scripts/build_patched_reclient.sh" "$rom" || { _rbe_err "reclient build failed."; return 1; }
  fi
  [ -d "$RBE_HOME/reclient-fix" ] || cp -a "$fix" "$RBE_HOME/reclient-fix" 2>/dev/null
  return 0
}

# ---------- environment ----------
_rbe_env() {
  local rom="$1" ram_gb cores jobs xmx
  ram_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null); ram_gb=${ram_gb:-16}
  cores=$(nproc 2>/dev/null || echo 8)
  xmx=$(( ram_gb / 4 )); [ "$xmx" -gt 16 ] && xmx=16; [ "$xmx" -lt 4 ] && xmx=4
  jobs="${NINJA_REMOTE_NUM_JOBS:-150}"

  export USE_RBE=1 USE_REWRAPPER=true
  export RBE_DIR="$rom/prebuilts/remoteexecution-client/buildbuddyfix"
  export RBE_service="remote.buildbuddy.io:443"
  export RBE_remote_headers="x-buildbuddy-api-key=${BUILDBUDDY_API_KEY}"
  export RBE_service_no_auth=true RBE_use_rpc_credentials=false
  export RBE_use_application_default_credentials=false
  export RBE_use_unified_downloads=true RBE_use_unified_uploads=true
  export NINJA_REMOTE_NUM_JOBS="$jobs"
  export RBE_cas_concurrency=100
  export RBE_enable_deps_cache=true RBE_deps_cache_max_mb=2048
  export RBE_local_resource_fraction=0.85
  local t
  for t in CXX CXX_LINKS JAVAC R8 D8 METALAVA TURBINE SIGNAPK JAR ZIP; do
    export "RBE_${t}=1" "RBE_${t}_EXEC_STRATEGY=remote_local_fallback"
  done
  export RBE_JAVA_POOL=default RBE_METALAVA_POOL=default RBE_LINT_POOL=default
  if [ -d /dev/shm ] && [ "$(df -BG --output=size /dev/shm 2>/dev/null | tail -1 | tr -dc 0-9)" -ge 16 ] 2>/dev/null; then
    export TMPDIR=/dev/shm
  fi
  if command -v ccache >/dev/null 2>&1; then
    export USE_CCACHE=1 CCACHE_EXEC="$(command -v ccache)"
  fi
  export _JAVA_OPTIONS="-XX:+UseParallelGC -Xms2g -Xmx${xmx}g -XX:MaxMetaspaceSize=1g"
}

# ---------- main entry ----------
rbe_auto() {
  local rom tools
  rom="$(_rbe_find_rom "$1")" || { _rbe_err "No ROM directory. Stopping."; return 1; }
  mkdir -p "$RBE_HOME"; chmod 700 "$RBE_HOME"
  echo "$rom" > "$RBE_HOME/rom_dir"
  _rbe_say "ROM: $rom"

  _rbe_load_key || { _rbe_err "No working key. Stopping."; return 1; }

  tools="$(_rbe_find_tools)" || { _rbe_err "Could not get tools repo."; return 1; }
  _rbe_patch "$rom" "$tools"   || return 1
  _rbe_reclient "$rom" "$tools" || return 1
  _rbe_env "$rom"

  if ! pgrep -f 'soong_ui|ninja ' >/dev/null 2>&1; then
    pkill -f reproxy 2>/dev/null; pkill -f rewrapper 2>/dev/null
  fi
  cd "$rom" || return 1
  # shellcheck disable=SC1091
  source build/envsetup.sh
  _rbe_say "RBE ready. account=$RBE_ACTIVE_ACCOUNT jobs=$NINJA_REMOTE_NUM_JOBS"
  _rbe_say "Now: lunch <target>   (or: rbe_build <target> [goal])"
  return 0
}

rbe_build() {
  local target="$1" goal="${2:-bacon}" log="$HOME/build.log" rc
  [ -n "$target" ] || { _rbe_err "usage: rbe_build <lunch-target> [goal]"; return 1; }
  rbe_auto "$3" || return 1
  lunch "$target" || return 1
  m -j"$(nproc)" "$goal" 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
  echo
  if grep -q 'RBE Stats' "$log"; then
    grep 'RBE Stats' "$log" | tail -1
    if grep 'RBE Stats' "$log" | tail -1 | grep -q 'down 0 B, up 0 B'; then
      _rbe_warn "RBE moved 0 bytes. Remote build did NOT run. Check out/soong/rbe/reproxy.ERROR"
    fi
  fi
  return "$rc"
}

