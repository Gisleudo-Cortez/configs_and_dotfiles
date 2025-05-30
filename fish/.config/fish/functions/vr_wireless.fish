function vr-wireless
    set -gx __NV_PRIME_RENDER_OFFLOAD 1
    set -gx __GLX_VENDOR_LIBRARY_NAME nvidia
    prime-run steam &
    alvr_dashboard --background
end
