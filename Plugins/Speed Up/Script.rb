module Input

REPEL_STAGES = [0,1]
$inf_repel = 0

  def self.update
    update_KGC_ScreenCapture
    if trigger?(Input::F8)
      pbScreenCapture
    end
    if $CanToggle && trigger?(Input::AUX1) #remap your Q button on the F1 screen to change your speedup switch
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
    end
    if trigger?(Input::AUX2) && $game_temp.in_menu == false && $game_temp.message_window_showing == false && $repel_toggle
      $inf_repel += 1
      $game_variables[202] = $inf_repel
      $inf_repel = 0 if $inf_repel >= REPEL_STAGES.size
      $PokemonGlobal.repel = REPEL_STAGES[$inf_repel]
      $PokemonGlobal.repel == 0 ? pbMessage(_INTL("Infinite Repel Disabled.")) : pbMessage(_INTL("Infinite Repel Enabled."))
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
