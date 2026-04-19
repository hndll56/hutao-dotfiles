if status is-interactive

    # Greeting
    set -U fish_greeting

    # Fastfetch
    fastfetch --config arch

    # Starship prompt
    source (/usr/local/bin/starship init fish --print-full-init | psub)

    # Yazi file manager dengan cd otomatis
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

end
