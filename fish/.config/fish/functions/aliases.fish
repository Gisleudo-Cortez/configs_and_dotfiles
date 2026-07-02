function aliases --description 'Show all aliases and abbreviations in a clean format'
    echo -e "\e[1;36mAliases:\e[0m"
    alias
    echo -e "\n\e[1;36mAbbreviations:\e[0m"
    abbr --show | string match -e 'abbr -a -- *' | string replace -r 'abbr -a -- (\S+) (.+)' '$1 \e[90m→\e[0m $2'
end