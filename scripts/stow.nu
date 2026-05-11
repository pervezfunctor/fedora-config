#!/usr/bin/env nu

use std/log
use ./lib.nu *

def is-symlink [path: string]: nothing -> bool {
  (do -i { ^readlink $path } | is-not-empty)
}

def dir-exists [path: string]: nothing -> bool {
  if not ($path | path exists) { return false }
  ($path | path type) == "dir"
}

def ensure-parent-dir [path: string] {
  let parent = ($path | path expand | path dirname)
  if not (dir-exists $parent) {
    log info $"creating directory: ($parent)"
    mkdir $parent
  }
}

def link [source: string, target: string]: nothing -> bool {
  let dot_dir = $env.DOT_DIR
  let src = ($source | path expand)
  let target = ($target | path expand)

  if not ($src | path exists) {
    log error $"Skipping: ($src) does not exist"
    return false
  }

  if not ($src | str starts-with $"($dot_dir)/") {
    log error $"Skipping: ($src) is outside ($dot_dir)"
    return false
  }

  ensure-parent-dir $target

  let is_symlink = (is-symlink $target)
  let exists = ($target | path exists) or $is_symlink

  if $is_symlink {
    let resolved = (do -i { ^readlink -f $target } | str trim)
    if $resolved == $src {
      log info $"Skipping: ($target) already links to ($src)"
      return true
    }
  } else if (dir-exists $target) {
    log error $"Skipping: ($target) is a directory"
    return false
  }

  if $exists {
    log warning $"Trashing existing ($target), restore with 'trash-restore'"
    do -i { ^trash $target }
  }

  log info $"Linking ($src) -> ($target)"
  ^ln -s $src $target
  true
}

def dotify-path [p: string]: nothing -> string {
  $p | path split | each {|seg|
    if ($seg | str starts-with "dot-") {
      $".($seg | str substring 4..)"
    } else {
      $seg
    }
  } | path join
}

def link-all [source: string, target: string] {
  let root = ($source | path expand)
  let target = ($target | path expand)

  for f in (glob $"($root)/**/*" --no-dir) {
    let src = ($f | path expand)
    let rel = ($src | path relative-to $root)
    let dst = ($target | path join (dotify-path $rel))
    link $src $dst
  }
}

export def "main config" [package: string] {
  link-all ($env.DOT_DIR | path join $package) ($env.HOME | path join ".config" $package)
}

export def "main home" [package: string] {
  link-all ($env.DOT_DIR | path join $package) $env.HOME
}

def "main help" [] {
  print $"Usage: stow <command> [package]

Commands:
  config <package>    Symlink package files to ~/.config/<package>
  home <package>      Symlink package files to ~/
  help                Show this help message

Run without a command to stow package to ~/.config \(same as config\)."
}

def main [package: string] {
  main config $package
}
