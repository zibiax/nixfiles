#!/usr/bin/env sh
# Update status for the quickshell bar, as one line of JSON:
#   behind   commits on GitHub's master not in the local checkout
#   inputs   flake inputs whose locked date differs between the local and
#            GitHub flake.lock ({name, from, to}, dates as YYYY-MM-DD)
#   rebuild  the running system's nixpkgs isn't the one in the local lock
#   offline  GitHub couldn't be reached (the rest compares local state only)
# Fetches over HTTPS, so it works without the SSH key loaded.

repo="$HOME/nixfiles"
cd "$repo" 2>/dev/null || { echo '{"error":"no ~/nixfiles checkout"}'; exit 0; }

url=$(git remote get-url origin | sed -E 's#^git@([^:]+):#https://\1/#')
if git fetch -q "$url" master 2>/dev/null; then
	offline=false
	remote=FETCH_HEAD
else
	offline=true
	remote=HEAD
fi

behind=$(git rev-list --count "HEAD..$remote")

running=$(nixos-version --json 2>/dev/null | jq -r '.nixpkgsRevision // empty')
locked=$(jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev' flake.lock)
rebuild=false
[ -n "$running" ] && [ "$running" != "$locked" ] && rebuild=true

# Root inputs only; transitive ones follow from these.
git show "$remote:flake.lock" | jq -c \
	--slurpfile local flake.lock \
	--argjson behind "$behind" \
	--argjson rebuild "$rebuild" \
	--argjson offline "$offline" '
	def date(n): n.locked.lastModified // 0 | strftime("%Y-%m-%d");
	. as $remote
	| {
		behind: $behind,
		rebuild: $rebuild,
		offline: $offline,
		inputs: [
			$remote.nodes.root.inputs | to_entries[]
			| select(.value | type == "string")
			| .key as $name
			| ($local[0].nodes[$local[0].nodes.root.inputs[$name] // ""] // {}) as $old
			| $remote.nodes[.value] as $new
			| select($old.locked.lastModified != $new.locked.lastModified)
			| { name: $name, from: date($old), to: date($new) }
		]
	}'
