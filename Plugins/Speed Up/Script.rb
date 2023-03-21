module Input

  def self.update
    update_KGC_ScreenCapture
    if trigger?(Input::F8)
      pbScreenCapture
    end
    if $CanToggle && trigger?(Input::AUX1) #remap your Q button on the F1 screen to change your speedup switch
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
    end
    if trigger?(Input::AUX2) && $game_temp.in_menu == false && $game_temp.message_window_showing == false && $game_map.map_id == 32
      pbTimeChanger
    end
  end
end

SPEEDUP_STAGES = [1,3]
$GameSpeed = 0
$frame = 0
$CanToggle = true
$repel_toggle = false

module Graphics
  class << Graphics
    alias fast_forward_update update
  end

  def self.update
    $frame += 1
    return unless $frame % SPEEDUP_STAGES[$GameSpeed] == 0
    fast_forward_update
    $frame = 0
  end
end
