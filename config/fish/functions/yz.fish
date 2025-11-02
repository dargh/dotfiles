function yz
    set target (yazi --chooser-file=/tmp/yazi-cd)
    if test -f /tmp/yazi-cd
        cd (cat /tmp/yazi-cd); or echo "Échec du cd vers (cat /tmp/yazi-cd)"
        rm /tmp/yazi-cd
    end
end
