#!/usr/bin/env nu

# Manage custom keyboard shortcuts in GNOME
#
# Examples:
#   Create a terminal shortcut:
#   > nu gnome-shortcut.nu create "Terminal" -c "ptyxis -s" -s "<Super>Return"
#
#   Create a file manager shortcut:
#   > nu gnome-shortcut.nu create "File Manager" -c "nautilus" -s "<Super>e"
#
#   Create a screenshot shortcut:
#   > nu gnome-shortcut.nu create "Screenshot" -c "gnome-screenshot -i" -s "<Shift><Super>s"
#
#   Create a lock screen shortcut:
#   > nu gnome-shortcut.nu create "Lock Screen" -c "loginctl lock-session" -s "<Super>l"
#
#   List all custom shortcuts:
#   > nu gnome-shortcut.nu list

def "parse-gsettings-list" [input: string] {
    if $input == "@as []" {
        []
    } else {
        $input
            | str replace -a "[" ""
            | str replace -a "]" ""
            | str replace -a "'" ""
            | split row ","
            | each { |s| $s | str trim }
            | where { |s| $s != "" }
    }
}

def "main create" [
    name: string              # Display name for the shortcut
    --command (-c): string    # Command to execute
    --shortcut (-s): string   # Keyboard shortcut (e.g., "<Super>t")
] {
    let schema = "org.gnome.settings-daemon.plugins.media-keys"
    let existing_str = (gsettings get $schema custom-keybindings | str trim)
    let existing = (parse-gsettings-list $existing_str)

    let new_index = ($existing | length)
    let new_binding = $"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom($new_index)/"

    let updated_bindings = ($existing | append $new_binding)
    let formatted_list = $"[($updated_bindings | each { |b| $"'($b)'" } | str join ', ')]"

    gsettings set $schema custom-keybindings $formatted_list
    gsettings set $"($schema).custom-keybinding:($new_binding)" name $name
    gsettings set $"($schema).custom-keybinding:($new_binding)" command $command
    gsettings set $"($schema).custom-keybinding:($new_binding)" binding $shortcut

    print $"(ansi green)✓(ansi reset) Created: ($name) → ($command) [($shortcut)]"
}

def "main list" [] {
    let schema = "org.gnome.settings-daemon.plugins.media-keys"
    let existing_str = (gsettings get $schema custom-keybindings | str trim)
    let bindings = (parse-gsettings-list $existing_str)

    if ($bindings | is-empty) {
        print "No custom keyboard shortcuts configured."
        return null
    }

    $bindings | each { |binding|
        let name = (gsettings get $"($schema).custom-keybinding:($binding)" name | str trim | str replace -a "'" "")
        let command = (gsettings get $"($schema).custom-keybinding:($binding)" command | str trim | str replace -a "'" "")
        let shortcut = (gsettings get $"($schema).custom-keybinding:($binding)" binding | str trim | str replace -a "'" "")

        {
            name: $name,
            command: $command,
            binding: $shortcut
        }
    } | table
}

def "main help" [] {
    print "Manage custom keyboard shortcuts in GNOME"
    print ""
    print "Subcommands:"
    print "  create <name> -c <cmd> -s <key>  - Create a new keyboard shortcut"
    print "  list                             - List all custom shortcuts"
    print "  help                             - Show this help message"
    print ""
    print "Examples:"
    print "  nu gnome-shortcut.nu create \"Terminal\" -c \"ptyxis -s\" -s \"<Super>Return\""
    print "  nu gnome-shortcut.nu create \"File Manager\" -c \"nautilus\" -s \"<Super>e\""
    print "  nu gnome-shortcut.nu create \"Screenshot\" -c \"gnome-screenshot -i\" -s \"<Shift><Super>s\""
    print "  nu gnome-shortcut.nu create \"Lock Screen\" -c \"loginctl lock-session\" -s \"<Super>l\""
    print "  nu gnome-shortcut.nu list"
}

def main [] {
    main help
}
