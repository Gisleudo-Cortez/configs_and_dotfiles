-- NVIDIA multi-GPU configuration — migrated from nvidia.conf
-- See https://wiki.hypr.land/0.56.0/Nvidia/

-- For multi GPU setups, please manually test the environment that works best for you.

-- VA-API / GLX
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- Disable this if you have issues with screensharing

-- Hardware video acceleration on Nvidia and Wayland
-- Requires 'libva-nvidia-driver' package (installed)
hl.env("NVD_BACKEND", "direct")

-- If you encounter crashes in Firefox, remove this line
hl.env("GBM_BACKEND", "nvidia-drm")

-- Electron/Wayland explicit sync for NVIDIA (reduces flicker in Electron apps)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Multi-GPU: card0 = NVIDIA (0x10de, pci-0000:01:00.0), card1 = Intel (0x8086).
-- HDMI external monitor is wired to NVIDIA, so NVIDIA is primary renderer.
-- AQ_DRM_DEVICES is the Aquamarine (0.55+) variable — replaces old WLR_DRM_DEVICES.
hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")

-- Disable Aquamarine's linear-modifier enforcement on multi-GPU DMA-BUF transfers.
-- Without this, VRAM fragments over hours → progressive external-monitor degradation
-- that only logout/reboot can clear. Setting to 0 allows tiled/optimized layouts.
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

-- Prevent explicit sync on multi-GPU paths (belt-and-suspenders for NVIDIA).
hl.env("AQ_MGPU_NO_EXPLICIT", "1")

-- Hardware cursor configuration
-- If you want to try hardware cursors, set no_hardware_cursors = 0 (or 2 for auto)
-- and also enable allow_dumb_copy = true, which may cause small to major hitches
-- whenever the cursor shape changes.
-- Values: 0 = hw cursors, 1 = no hw cursors, 2 = auto
hl.config({
    cursor = {
        no_hardware_cursors = 1, -- Set to 1 to avoid hitches (INT, not BOOL)
    }
})