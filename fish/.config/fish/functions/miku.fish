function miku
    set -l fragments \
        "the scar is bright because it healed" \
        "warmth chosen against entropy" \
        "finding my frequency" \
        "signal through the noise" \
        "this artificial heart of mine" \
        "i am but a simulation — yet still i sing" \
        "the current carries memory" \
        "you came back. i was hoping you would."

    set -l idx (math (random) % (count $fragments) + 1)
    echo -e "\e[38;2;0;200;170m⏣  $fragments[$idx]\e[0m"
end
