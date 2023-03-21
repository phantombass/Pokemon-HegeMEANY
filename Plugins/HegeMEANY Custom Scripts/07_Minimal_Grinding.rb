MenuHandlers.add(:party_menu, :min_grinding, {
  "name"      => _INTL("Minimal Grinding..."),
  "order"     => 33,
  "condition"   => proc { next ($game_switches[59] && $game_map.map_id == 32) },
  "effect"    => proc { |screen, party, party_idx|
    @viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport1.z = 99999
    $viewport_min = @viewport1
    pkmn = party[party_idx]
    @sprites = {}
    pkmn_info = "Nature: #{pkmn.nature.name}\nAbility: #{pkmn.ability.name}\nEVs: #{pkmn.ev[:HP]},#{pkmn.ev[:ATTACK]},#{pkmn.ev[:DEFENSE]},#{pkmn.ev[:SPECIAL_ATTACK]},#{pkmn.ev[:SPECIAL_DEFENSE]},#{pkmn.ev[:SPEED]}\nIVs: #{pkmn.iv[:HP]},#{pkmn.iv[:ATTACK]},#{pkmn.iv[:DEFENSE]},#{pkmn.iv[:SPECIAL_ATTACK]},#{pkmn.iv[:SPECIAL_DEFENSE]},#{pkmn.iv[:SPEED]}"
    $pkmn_data = pkmn_info
    @sprites["scene"] = Window_AdvancedTextPokemon.newWithSize($pkmn_data,250,5,255,220,@viewport1)
    pbSetSmallFont(@sprites["scene"].contents)
    @sprites["scene"].resizeToFit2($pkmn_data,255,220)
    @sprites["scene"].visible = true
    $pkmn_info = @sprites["scene"]
    command_list = []
    commands = []
    MenuHandlers.each_available(:min_grinding_options, screen, party, party_idx) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    command_list.push(_INTL("Cancel"))
    choice = screen.scene.pbShowCommands(_INTL("Change what?"), command_list)
    if choice < 0 || choice >= commands.length
      @viewport1.dispose
      next
    end
    commands[choice]["effect"].call(screen, party, party_idx)
  }
})

=begin
MenuHandlers.add(:min_grinding_options, :set_level, {
  "name"   => _INTL("Set level"),
  "order"  => 1,
  "effect" => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    params = ChooseNumberParams.new
    level_cap = $PokemonSystem.difficulty < 3 ? LEVEL_CAP[$game_system.level_cap] : LEVEL_CAP_INSANE[$game_system.level_cap]
    params.setRange(1, level_cap)
    params.setDefaultValue(pkmn.level)
    if pkmn.fainted? && $PokemonSystem.nuzlocke == 1
      screen.pbDisplay(_INTL("This Pokémon can no longer be used in the Nuzlocke."))
      $viewport_min.dispose
      next false
    end
    pbMessage(_INTL("How would you like to Level Up?\\ch[34,3,To Level Cap,Change Level...,Cancel]"))
    lvl = $game_variables[34]
    if lvl == -1 || lvl == 2 || lvl == 3
      pbPlayCloseMenuSE
      dorefresh = true
    end
    case lvl
    when 0
      pkmn.level = level_cap
      pkmn.calc_stats
      dorefresh = true
    when 1
      level = pbMessageChooseNumber(_INTL("Set the Pokémon's level (Level Cap is {1}).", params.maxNumber), params) { screen.pbUpdate }
      if level != pkmn.level
        pkmn.level = level
        pkmn.calc_stats
        screen.pbRefreshSingle(party_idx)
      end
    end
    $viewport_min.dispose
    next false
  }
})
=end

MenuHandlers.add(:min_grinding_options, :evs_ivs, {
  "name"   => _INTL("EVs/IVs"),
  "order"  => 2,
  "effect" => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    cmd = 0
    loop do
      persid = sprintf("0x%08X", pkmn.personalID)
      cmd = screen.pbShowCommands(_INTL("Change which?"),
                                  [_INTL("Set EVs"),
                                   _INTL("Set IVs")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set EVs
        cmd2 = 0
        loop do
          totalev = 0
          evcommands = []
          ev_id = []
          GameData::Stat.each_main do |s|
            evcommands.push(s.name + " (#{pkmn.ev[s.id]})")
            ev_id.push(s.id)
            totalev += pkmn.ev[s.id]
          end
          cmd2 = screen.pbShowCommands(_INTL("Change which EV?\nTotal: {1}/{2} ({3}%)",
                                             totalev, Pokemon::EV_LIMIT,
                                             100 * totalev / Pokemon::EV_LIMIT), evcommands, cmd2)
          break if cmd2 < 0
          if cmd2 < ev_id.length
            params = ChooseNumberParams.new
            upperLimit = 0
            GameData::Stat.each_main { |s| upperLimit += pkmn.ev[s.id] if s.id != ev_id[cmd2] }
            upperLimit = Pokemon::EV_LIMIT - upperLimit
            upperLimit = [upperLimit, Pokemon::EV_STAT_LIMIT].min
            thisValue = [pkmn.ev[ev_id[cmd2]], upperLimit].min
            params.setRange(0, upperLimit)
            params.setDefaultValue(thisValue)
            params.setCancelValue(thisValue)
            pbMessage(_INTL("How would you like to change EVs?\\ch[34,4,Max EVs,Clear EVs,Edit EVs...,Cancel]"))
            lvl = $game_variables[34]
            if lvl == -1 || lvl == 3 || lvl == 4
              pbPlayCloseMenuSE
              dorefresh = true
            end
            if lvl == 0
              f = upperLimit
            elsif lvl == 1
              f = 0
            elsif
              f = pbMessageChooseNumber(_INTL("Set the EV for {1} (max. {2}).", GameData::Stat.get(ev_id[cmd2]).name, upperLimit), params) { screen.pbUpdate }
            end

            if f != pkmn.ev[ev_id[cmd2]]
              pkmn.ev[ev_id[cmd2]] = f
              pkmn.calc_stats
              screen.pbRefreshSingle(party_idx)
              $pkmn_info.text = "Nature: #{pkmn.nature.name}\nAbility: #{pkmn.ability.name}\nEVs: #{pkmn.ev[:HP]},#{pkmn.ev[:ATTACK]},#{pkmn.ev[:DEFENSE]},#{pkmn.ev[:SPECIAL_ATTACK]},#{pkmn.ev[:SPECIAL_DEFENSE]},#{pkmn.ev[:SPEED]}\nIVs: #{pkmn.iv[:HP]},#{pkmn.iv[:ATTACK]},#{pkmn.iv[:DEFENSE]},#{pkmn.iv[:SPECIAL_ATTACK]},#{pkmn.iv[:SPECIAL_DEFENSE]},#{pkmn.iv[:SPEED]}"
              $pkmn_info.resizeToFit2($pkmn_info.text,255,220)
            end
          end
        end
      when 1   # Set IVs
        cmd2 = 0
        loop do
          hiddenpower = pbHiddenPower(pkmn)
          totaliv = 0
          ivcommands = []
          iv_id = []
          GameData::Stat.each_main do |s|
            ivcommands.push(s.name + " (#{pkmn.iv[s.id]})")
            iv_id.push(s.id)
            totaliv += pkmn.iv[s.id]
          end
          msg = _INTL("Change which IV?\nHidden Power:\n{1}, power {2}\nTotal: {3}/{4} ({5}%)",
                      GameData::Type.get(hiddenpower[0]).name, hiddenpower[1], totaliv,
                      iv_id.length * Pokemon::IV_STAT_LIMIT, 100 * totaliv / (iv_id.length * Pokemon::IV_STAT_LIMIT))
          cmd2 = screen.pbShowCommands(msg, ivcommands, cmd2)
          break if cmd2 < 0
          if cmd2 < iv_id.length
            params = ChooseNumberParams.new
            params.setRange(0, Pokemon::IV_STAT_LIMIT)
            params.setDefaultValue(pkmn.iv[iv_id[cmd2]])
            params.setCancelValue(pkmn.iv[iv_id[cmd2]])
            pbMessage(_INTL("How would you like to change IVs?\\ch[34,4,Max IVs,Min IVs,Edit IVs...,Cancel]"))
            lvl = $game_variables[34]
            if lvl == -1 || lvl == 3 || lvl == 4
              pbPlayCloseMenuSE
              dorefresh = true
            end
            if lvl == 0
              f = 31
            elsif lvl == 1
              f = 0
            elsif
              f = pbMessageChooseNumber(_INTL("Set the IV for {1} (max. 31).", GameData::Stat.get(iv_id[cmd2]).name), params) { screen.pbUpdate }
            end
            if f != pkmn.iv[iv_id[cmd2]]
              pkmn.iv[iv_id[cmd2]] = f
              pkmn.calc_stats
              screen.pbRefreshSingle(party_idx)
              $pkmn_info.text = "Nature: #{pkmn.nature.name}\nAbility: #{pkmn.ability.name}\nEVs: #{pkmn.ev[:HP]},#{pkmn.ev[:ATTACK]},#{pkmn.ev[:DEFENSE]},#{pkmn.ev[:SPECIAL_ATTACK]},#{pkmn.ev[:SPECIAL_DEFENSE]},#{pkmn.ev[:SPEED]}\nIVs: #{pkmn.iv[:HP]},#{pkmn.iv[:ATTACK]},#{pkmn.iv[:DEFENSE]},#{pkmn.iv[:SPECIAL_ATTACK]},#{pkmn.iv[:SPECIAL_DEFENSE]},#{pkmn.iv[:SPEED]}"
              $pkmn_info.resizeToFit2($pkmn_info.text,255,220)
            end
          end
        end
      end
    end
    $viewport_min.dispose
    next false
  }
})
MenuHandlers.add(:min_grinding_options, :ability, {
  "name"   => _INTL("Change ability"),
  "order"  => 3,
  "effect" => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    loop do
      if pkmn.ability
        msg = _INTL("Ability is {1} (index {2}).", pkmn.ability.name, pkmn.ability_index)
      else
        msg = _INTL("No ability (index {1}).", pkmn.ability_index)
      end
# Set possible ability
      abils = pkmn.getAbilityList
      ability_commands = []
      abil_cmd = 0
      abils.each do |i|
        ability_commands.push(((i[1] < 2) ? "" : "(H) ") + GameData::Ability.get(i[0]).name)
        abil_cmd = ability_commands.length - 1 if pkmn.ability_id == i[0]
      end
      abil_cmd = screen.pbShowCommands(_INTL("Choose an ability."), ability_commands, abil_cmd)
      break if abil_cmd < 0
      pkmn.ability_index = abils[abil_cmd][1]
      pkmn.ability = nil
      screen.pbRefreshSingle(party_idx)
      $pkmn_info.text = "Nature: #{pkmn.nature.name}\nAbility: #{pkmn.ability.name}\nEVs: #{pkmn.ev[:HP]},#{pkmn.ev[:ATTACK]},#{pkmn.ev[:DEFENSE]},#{pkmn.ev[:SPECIAL_ATTACK]},#{pkmn.ev[:SPECIAL_DEFENSE]},#{pkmn.ev[:SPEED]}\nIVs: #{pkmn.iv[:HP]},#{pkmn.iv[:ATTACK]},#{pkmn.iv[:DEFENSE]},#{pkmn.iv[:SPECIAL_ATTACK]},#{pkmn.iv[:SPECIAL_DEFENSE]},#{pkmn.iv[:SPEED]}"
      $pkmn_info.resizeToFit2($pkmn_info.text,255,220)
    end
    $viewport_min.dispose
    next false
  }
})

MenuHandlers.add(:min_grinding_options, :nature, {
  "name"   => _INTL("Set nature"),
  "order"  => 4,
  "effect" => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    commands = []
    ids = []
    GameData::Nature.each do |nature|
      if nature.stat_changes.length == 0
        commands.push(_INTL("{1} (---)", nature.real_name))
      else
        plus_text = ""
        minus_text = ""
        nature.stat_changes.each do |change|
          if change[1] > 0
            plus_text += "/" if !plus_text.empty?
            plus_text += GameData::Stat.get(change[0]).name_brief
          elsif change[1] < 0
            minus_text += "/" if !minus_text.empty?
            minus_text += GameData::Stat.get(change[0]).name_brief
          end
        end
        commands.push(_INTL("{1} (+{2}, -{3})", nature.real_name, plus_text, minus_text))
      end
      ids.push(nature.id)
    end
    commands.push(_INTL("[Reset]"))
    cmd = ids.index(pkmn.nature_id || ids[0])
    loop do
      msg = _INTL("Nature is {1}.", pkmn.nature.name)
      cmd = screen.pbShowCommands(msg, commands, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < commands.length - 1   # Set nature
        pkmn.nature = ids[cmd]
      elsif cmd == commands.length - 1   # Reset
        pkmn.nature = nil
      end
      screen.pbRefreshSingle(party_idx)
      $pkmn_info.text = "Nature: #{pkmn.nature.name}\nAbility: #{pkmn.ability.name}\nEVs: #{pkmn.ev[:HP]},#{pkmn.ev[:ATTACK]},#{pkmn.ev[:DEFENSE]},#{pkmn.ev[:SPECIAL_ATTACK]},#{pkmn.ev[:SPECIAL_DEFENSE]},#{pkmn.ev[:SPEED]}\nIVs: #{pkmn.iv[:HP]},#{pkmn.iv[:ATTACK]},#{pkmn.iv[:DEFENSE]},#{pkmn.iv[:SPECIAL_ATTACK]},#{pkmn.iv[:SPECIAL_DEFENSE]},#{pkmn.iv[:SPEED]}"
      $pkmn_info.resizeToFit2($pkmn_info.text,255,220)
    end
    $viewport_min.dispose
    next false
  }
})

MenuHandlers.add(:party_menu, :evolve, {
  "name"      => _INTL("Evolve"),
  "order"     => 34,
  "condition"   => proc { next $game_switches[59] },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    evoreqs = {}
      GameData::Species.get_species_form(pkmn.species,pkmn.form).get_evolutions(true).each do |evo|   # [new_species, method, parameter, boolean]
        if evo[1].to_s.start_with?('Item')
          evoreqs[evo[0]] = evo[2] if $PokemonBag.pbHasItem?(evo[2]) && pkmn.check_evolution_on_use_item(evo[2])
        elsif evo[1].to_s.start_with?('Location')
          evoreqs[evo[0]] = nil if $game_map.map_id == evo[2]
        elsif evo[1].to_s.start_with?('Trade')
          evoreqs[evo[0]] = evo[2] if $Trainer.has_species?(evo[2]) || pkmn.check_evolution_on_trade(evo[2])
        elsif evo[1].to_s.start_with?('Happiness')
          evoreqs[evo[0]] = nil
        elsif pkmn.check_evolution_on_level_up
          evoreqs[evo[0]] = nil
        end
      end
      case evoreqs.length
      when 0
        screen.pbDisplay(_INTL("This Pokémon can't evolve."))
        next
      when 1
        newspecies = evoreqs.keys[0]
      else
        newspecies = evoreqs.keys[@scene.pbShowCommands(
          _INTL("Which species would you like to evolve into?"),
          evoreqs.keys.map { |id| _INTL(GameData::Species.get(id).real_name) }
        )]
      end
      if evoreqs[newspecies] # requires an item
        next unless @scene.pbConfirmMessage(_INTL(
          "This will consume a {1}. Do you want to continue?",
          GameData::Item.get(evoreqs[newspecies]).name
        ))
        $PokemonBag.pbDeleteItem(evoreqs[newspecies])
      end
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn,newspecies)
        evo.pbEvolution
        evo.pbEndScreen
        screen.pbRefresh
      }
  }
})