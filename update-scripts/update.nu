#!/usr/bin/env nix run nixpkgs#nushell --
#
# to invoke generate_sources directly, enter nushell and run
# `use update.nu`
# `update generate_sources`

def get_latest_release [repo: string]: nothing -> string {
  try {
  	http get $"https://api.github.com/repos/($repo)/releases"
  	  | where prerelease == false
  	  | where tag_name != "twilight"
  	  | get tag_name
  	  | get 0
  } catch { |err| $"Failed to fetch latest release, aborting: ($err.msg)" }
}

def get_nix_hash [version: string, arch: string]: nothing -> string  {
  nix store prefetch-file --hash-type sha256 --json (build_url $version $arch) | from json | get hash
}

def build_url [version: string, arch: string]: nothing -> string {
  return $"https://github.com/zen-browser/desktop/releases/download/($version)/zen.linux-($arch).tar.xz"
}


export def generate_sources []: nothing -> record {
  let tag = get_latest_release "zen-browser/desktop"
  let prev: record = open ./sources.json
  mut stable = $prev.stable

  if $tag != $prev.stable.version {
    $stable = {
    	version: $tag
    	x86_64-linux: (get_nix_hash $tag "x86_64")
    	aarch64-linux: (get_nix_hash $tag "aarch64")
    }
  }

  let sources = {
    stable: $stable
    twilight: {
    	x86_64-linux: (get_nix_hash "twilight" "x86_64")
    	aarch64-linux: (get_nix_hash "twilight" "aarch64")
    }
  }

  echo $sources | save --force "sources.json"

  return {
    new_tag: $stable.version
    prev_tag: $prev.stable.version
  }
}
