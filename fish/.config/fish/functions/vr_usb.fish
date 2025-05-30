function vr-usb
    adb forward tcp:9943 tcp:9943
    adb forward tcp:9944 tcp:9944
    vr-wireless
end
