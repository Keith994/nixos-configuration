{ ... }:

{
  programs.dms-shell = {
    enable = true;

    # 这些先开着也可以，但 VM 暂时没必要全堆
    enableSystemMonitoring = true;

    enableVPN = false;
    enableDynamicTheming = true;
    enableAudioWavelength = false;
    enableCalendarEvents = false;
    enableClipboardPaste = true;
  };
}
