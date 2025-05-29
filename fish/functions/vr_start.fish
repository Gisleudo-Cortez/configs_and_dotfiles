function vr-start
    switch $argv[1]
        case wireless
            vr-wireless
        case usb
            vr-usb
        case '*'
            echo "Usage: vr-start {wireless|usb}"
    end
end

