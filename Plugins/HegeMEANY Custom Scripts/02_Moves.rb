class Battle::Move
  def beamMove?;         return @flags.any? { |f| f[/^Beam$/i] };               end
  def damageReducedByFreeze?;  return true;  end
  def pbAccuracyCheck(user, target)
    return true if @battle.field.terrain == :Swamp && type == (:POISON || :WATER)
    # "Always hit" effects and "always hit" accuracy
    return true if target.effects[PBEffects::Telekinesis] > 0
    return true if target.effects[PBEffects::Minimize] && tramplesMinimize? && Settings::MECHANICS_GENERATION >= 6
    baseAcc = pbBaseAccuracy(user, target)
    return true if baseAcc == 0
    # Calculate all multiplier effects
    modifiers = {}
    modifiers[:base_accuracy]  = baseAcc
    modifiers[:accuracy_stage] = user.stages[:ACCURACY]
    modifiers[:evasion_stage]  = target.stages[:EVASION]
    modifiers[:accuracy_multiplier] = 1.0
    modifiers[:evasion_multiplier]  = 1.0
    pbCalcAccuracyModifiers(user, target, modifiers)
    # Check if move can't miss
    return true if modifiers[:base_accuracy] == 0
    # Calculation
    accStage = [[modifiers[:accuracy_stage], -6].max, 6].min + 6
    evaStage = [[modifiers[:evasion_stage], -6].max, 6].min + 6
    stageMul = [3, 3, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9]
    stageDiv = [9, 8, 7, 6, 5, 4, 3, 3, 3, 3, 3, 3, 3]
    accuracy = 100.0 * stageMul[accStage] / stageDiv[accStage]
    evasion  = 100.0 * stageMul[evaStage] / stageDiv[evaStage]
    accuracy = (accuracy * modifiers[:accuracy_multiplier]).round
    evasion  = (evasion  * modifiers[:evasion_multiplier]).round
    evasion = 1 if evasion < 1
    threshold = modifiers[:base_accuracy] * accuracy / evasion
    # Calculation
    r = @battle.pbRandom(100)
    if Settings::AFFECTION_EFFECTS && @battle.internalBattle &&
       target.pbOwnedByPlayer? && target.affection_level == 5 && !target.mega?
      return true if r < threshold - 10
      target.damageState.affection_missed = true if r < threshold
      return false
    end
    return r < threshold
  end
  def pbCalcType(user)
    @powerBoost = false
    $orig_grass = false
    $orig_water = false
    $orig_flying = false
    $orig_type_ice = false
    ret = pbBaseType(user)
    if ret && GameData::Type.exists?(:ELECTRIC)
      if @battle.field.effects[PBEffects::IonDeluge] && ret == :NORMAL
        ret = :ELECTRIC
        @powerBoost = false
      end
      if user.effects[PBEffects::Electrify]
        ret = :ELECTRIC
        @powerBoost = false
      end
    end
    if ret && GameData::Type.exists?(:WATER)
      if @battle.field.field_effects == :Lava && ret == :ICE
        @battle.field.field_effects = :None
        ret = :WATER
        $orig_type_ice = true
        @powerBoost = false
      end
    end
    if ret && GameData::Type.exists?(:POISON)
      if @battle.field.field_effects == :ToxicFumes && ret == :WATER
        ret = :POISON
        $orig_water = true
        @powerBoost = false
      end
    end
    if ret && GameData::Type.exists?(:FIRE)
      if @battle.field.field_effects == :Fire && ret == :GRASS
        ret = :FIRE
        $orig_flying = false
        $orig_grass = true
        @powerBoost = false
      end
      if @battle.field.field_effects == :Fire && ret == :FLYING && specialMove?
        ret = :FIRE
        $orig_grass = false
        $orig_flying = true
        @powerBoost = false
      end
    end
    return ret
  end
  def pbCalcTypeModSingle(moveType, defType, user, target)
    ret = Effectiveness.calculate_one(moveType, defType)
    if Effectiveness.ineffective_type?(moveType, defType)
      # Ring Target
      if target.hasActiveItem?(:RINGTARGET)
        ret = Effectiveness::NORMAL_EFFECTIVE_ONE
      end
      # Foresight
      if (user.hasActiveAbility?(:SCRAPPY) || target.effects[PBEffects::Foresight]) &&
         defType == :GHOST
        ret = Effectiveness::NORMAL_EFFECTIVE_ONE
      end
      if user.hasActiveAbility?(:NITRIC) && defType == :STEEL
        ret = Effectiveness::NORMAL_EFFECTIVE_ONE
      end
      # Miracle Eye
      if target.effects[PBEffects::MiracleEye] && defType == :DARK
        ret = Effectiveness::NORMAL_EFFECTIVE_ONE
      end
    elsif Effectiveness.super_effective_type?(moveType, defType)
      # Delta Stream's weather
      if target.effectiveWeather == :StrongWinds && defType == :FLYING
        ret = Effectiveness::NORMAL_EFFECTIVE_ONE
      end
    end
    # Grounded Flying-type Pokémon become susceptible to Ground moves
    if !target.airborne? && defType == :FLYING && moveType == :GROUND
      ret = Effectiveness::NORMAL_EFFECTIVE_ONE
    end
    return ret
  end
  def pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    # Global abilities
    if (@battle.pbCheckGlobalAbility(:DARKAURA) && type == :DARK) ||
       (@battle.pbCheckGlobalAbility(:FAIRYAURA) && type == :FAIRY) || (@battle.pbCheckGlobalAbility(:GAIAFORCE) && type == :GROUND)
      if @battle.pbCheckGlobalAbility(:AURABREAK)
        multipliers[:base_damage_multiplier] *= 2 / 3.0
      else
        multipliers[:base_damage_multiplier] *= 4 / 3.0
      end
    end
    # Ability effects that alter damage
    if user.abilityActive?
      Battle::AbilityEffects.triggerDamageCalcFromUser(
        user.ability, user, target, self, multipliers, baseDmg, type
      )
    end
    if !@battle.moldBreaker
      # NOTE: It's odd that the user's Mold Breaker prevents its partner's
      #       beneficial abilities (i.e. Flower Gift boosting Atk), but that's
      #       how it works.
      user.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromAlly(
          b.ability, user, target, self, multipliers, baseDmg, type
        )
      end
      if target.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromTarget(
          target.ability, user, target, self, multipliers, baseDmg, type
        )
        Battle::AbilityEffects.triggerDamageCalcFromTargetNonIgnorable(
          target.ability, user, target, self, multipliers, baseDmg, type
        )
      end
      target.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromTargetAlly(
          b.ability, user, target, self, multipliers, baseDmg, type
        )
      end
    end
    # Item effects that alter damage
    if user.itemActive?
      Battle::ItemEffects.triggerDamageCalcFromUser(
        user.item, user, target, self, multipliers, baseDmg, type
      )
    end
    if target.itemActive?
      Battle::ItemEffects.triggerDamageCalcFromTarget(
        target.item, user, target, self, multipliers, baseDmg, type
      )
    end
    # Parental Bond's second attack
    if user.effects[PBEffects::ParentalBond] == 1
      multipliers[:base_damage_multiplier] /= (Settings::MECHANICS_GENERATION >= 7) ? 4 : 2
    end
    if user.effects[PBEffects::EchoChamber] == 1
      multipliers[:base_damage_multiplier] /= (Settings::MECHANICS_GENERATION >= 7) ? 4 : 2
    end
    # Other
    if user.effects[PBEffects::MeFirst]
      multipliers[:base_damage_multiplier] *= 1.5
    end
    if user.effects[PBEffects::HelpingHand] && !self.is_a?(Battle::Move::Confusion)
      multipliers[:base_damage_multiplier] *= 1.5
    end
    if user.effects[PBEffects::Charge] > 0 && type == :ELECTRIC
      multipliers[:base_damage_multiplier] *= 2
    end
    if $orig_type_ice
      @battle.pbDisplay(_INTL("The lava melted the ice!"))
      $field_effect_bg = "rocky"
      @battle.scene.pbRefreshEverything
      @battle.pbDisplay(_INTL("The melted ice cooled the lava!"))
      multipliers[:final_damage_multiplier] *= 0.8
      $orig_type_ice = false
    end
    # Mud Sport
    if type == :ELECTRIC
      if @battle.allBattlers.any? { |b| b.effects[PBEffects::MudSport] }
        multipliers[:base_damage_multiplier] /= 3
      end
      if @battle.field.effects[PBEffects::MudSportField] > 0
        multipliers[:base_damage_multiplier] /= 3
      end
    end
    # Water Sport
    if type == :FIRE
      if @battle.allBattlers.any? { |b| b.effects[PBEffects::WaterSport] }
        multipliers[:base_damage_multiplier] /= 3
      end
      if @battle.field.effects[PBEffects::WaterSportField] > 0
        multipliers[:base_damage_multiplier] /= 3
      end
    end
    # Terrain moves
    terrain_multiplier = (Settings::MECHANICS_GENERATION >= 8) ? 1.3 : 1.5
    case @battle.field.terrain
    when :Electric
      multipliers[:base_damage_multiplier] *= terrain_multiplier if type == :ELECTRIC && user.affectedByTerrain?
    when :Grassy
      multipliers[:base_damage_multiplier] *= terrain_multiplier if type == :GRASS && user.affectedByTerrain?
    when :Psychic
      multipliers[:base_damage_multiplier] *= terrain_multiplier if type == :PSYCHIC && user.affectedByTerrain?
    when :Misty
      multipliers[:base_damage_multiplier] /= 2 if type == :DRAGON && target.affectedByTerrain?
    end
    # Badge multipliers
    if @battle.internalBattle
      if user.pbOwnedByPlayer?
        if physicalMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_ATTACK
          multipliers[:attack_multiplier] *= 1.1
        elsif specialMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_SPATK
          multipliers[:attack_multiplier] *= 1.1
        end
      end
      if target.pbOwnedByPlayer?
        if physicalMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_DEFENSE
          multipliers[:defense_multiplier] *= 1.1
        elsif specialMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_SPDEF
          multipliers[:defense_multiplier] *= 1.1
        end
      end
    end
    # Multi-targeting attacks
    if numTargets > 1
      multipliers[:final_damage_multiplier] *= 0.75
    end
    # Weather
    case user.effectiveWeather
    when :Sun, :HarshSun
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] *= 1.5
      when :WATER
        multipliers[:final_damage_multiplier] /= 2
      end
    when :Rain, :HeavyRain
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] /= 2
      when :WATER
        multipliers[:final_damage_multiplier] *= 1.5
      end
    when :Sandstorm
      if target.pbHasType?(:ROCK) && specialMove? && @function != "UseTargetDefenseInsteadOfTargetSpDef"
        multipliers[:defense_multiplier] *= 1.5
      end
    end
    # Field Effects
    case user.effectiveField
    when :Desert
      case type
      when :FIRE, :GROUND
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The desert strengthened the attack!")) if $test_trigger == false
      when :WATER, :GRASS
        multipliers[:final_damage_multiplier] *= 0.8
        @battle.pbDisplay(_INTL("The desert weakened the attack!")) if $test_trigger == false
      when :FLYING
        if user.effectiveWeather != :Sandstorm
          @battle.field.weather = :Sandstorm
          @battle.field.weatherDuration = user.hasActiveItem?(:SMOOTHROCK) ? 8 : 5
          @battle.pbDisplay(_INTL("The winds kicked up a Sandstorm!")) if $test_trigger == false
        end
      end
    when :Lava
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The lava strengthened the attack!")) if $test_trigger == false
      end
    when :ToxicFumes
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] *= 1.2
        if user.effectiveWeather == :Rain
          @battle.pbDisplay(_INTL("The fumes strengthened the attack!")) if $test_trigger == false
        else
          @battle.pbDisplay(_INTL("The fumes strengthened the attack!")) if $test_trigger == false
          @battle.pbDisplay(_INTL("The field caught fire!")) if $test_trigger == false
          $field_effect_bg = "fire"
          @battle.scene.pbRefreshEverything
          @battle.field.field_effects = :Fire
          @battle.pbDisplay(_INTL("The field is ablaze.")) if $test_trigger == false
        end
      when :POISON
        multipliers[:final_damage_multiplier] *= 1.2
        if $orig_water == false
          @battle.pbDisplay(_INTL("The fumes strengthened the attack!")) if $test_trigger == false
        else
          @battle.pbDisplay(_INTL("The fumes corroded and strengthened the attack!")) if $test_trigger == false
        end
        $orig_water = false
      end
    when :Fire
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] *= 1.2
        if $orig_grass == false && $orig_flying == false
          @battle.pbDisplay(_INTL("The wildfire strengthened the attack!")) if $test_trigger == false
        elsif $orig_grass == true
          @battle.pbDisplay(_INTL("The plants caught fire and strengthened the attack!")) if $test_trigger == false
          $orig_grass = false
        elsif $orig_flying == true
          @battle.pbDisplay(_INTL("The winds kicked up cinders!")) if $test_trigger == false
          if $cinders == 0
            $cinders = 3
          end
          $orig_flying = false
        end
      when :WATER
        multipliers[:final_damage_multiplier] *= 0.8
        @battle.pbDisplay(_INTL("The wildfire weakened the attack!")) if $test_trigger == false
      end
    when :Swamp
      case type
      when :ROCK
        multipliers[:final_damage_multiplier] *= 0.8
        @battle.pbDisplay(_INTL("The swamp weakened the attack!")) if $test_trigger == false
        if self.baseDamage >= 80
          @battle.pbDisplay(_INTL("The swamp filled with rocks!")) if $test_trigger == false
          $field_effect_bg = "forest"
          @battle.scene.pbRefreshEverything
          @battle.field.field_effects = :None
        end
      when :FIRE, :FIGHTING
        multipliers[:final_damage_multiplier] *= 0.8
        @battle.pbDisplay(_INTL("The swamp weakened the attack!")) if $test_trigger == false
      when :POISON, :WATER, :GRASS
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The swamp strengthened the attack!")) if $test_trigger == false
      end
    when :City
      case type
      when :NORMAL, :POISON
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The city strengthened the attack!")) if $test_trigger == false
      when :FIRE
        if self.baseDamage >= 70 && specialMove? && user.effectiveWeather != :Rain && user.effectiveWeather != :HeavyRain && user.effectiveWeather != :AcidRain
          @battle.pbDisplay(_INTL("The city caught fire!")) if $test_trigger == false
          $field_effect_bg = "fire"
          @battle.scene.pbRefreshEverything
          @battle.field.field_effects = :Fire
          @battle.pbDisplay(_INTL("The field is ablaze.")) if $test_trigger == false
        end
      when :SOUND
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The city strengthened the attack!")) if $test_trigger == false
        @battle.allBattlers.each do |pkmn|
          confuse = rand(100)
          if confuse > 85
            @battle.pbDisplay(_INTL("The noise of the city was too much for {1}!",pkmn.name))
            pkmn.pbConfuse if pkmn.pbCanConfuse?
          end
        end
      when :GROUND
        if name == "Bulldoze" || name == "Earthquake" || name == "Stomping Tantrum"
          @battle.pbDisplay(_INTL("The city came crashing down!")) if $test_trigger == false
          $field_effect_bg = "rocky"
          @battle.scene.pbRefreshEverything
          @battle.field.field_effects = :None
          user.pbOwnSide.effects[PBEffects::StealthRock] = true if user.pbOwnSide.effects[PBEffects::StealthRock] == false
          target.pbOwnSide.effects[PBEffects::StealthRock] = true if target.pbOwnSide.effects[PBEffects::StealthRock] == false
          @battle.pbDisplay(_INTL("City rubble and rocks are scattered across each side!")) if $test_trigger == false
        end
      when :ELECTRIC
        if $outage == false
          multipliers[:final_damage_multiplier] *= 1.2
          @battle.pbDisplay(_INTL("The attack drew power from the city!")) if $test_trigger == false
          @battle.allOtherSideBattlers.each do |pkmn|
            pkmn.pbLowerStatStage(:ACCURACY,1,user) if !pkmn.pbHasType?(:ELECTRIC)
          end
          $field_effect_bg = "city_night"
          @battle.scene.pbRefreshEverything
          @battle.pbDisplay(_INTL("Power outage!")) if $test_trigger == false
          $outage = true
        end
      when :DARK, :GHOST
        if $outage == true
          multipliers[:final_damage_multiplier] *= 1.2
          if type == :DARK
            @battle.pbDisplay(_INTL("The city's darkness powered the attack!")) if $test_trigger == false
          else
            @battle.pbDisplay(_INTL("The shadows powered the attack!")) if $test_trigger == false
          end
        end
      end
    when :Ruins
      case type
      when :FIRE, :WATER, :GRASS
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The ruins strengthened the attack!")) if $test_trigger == false
      when :DRAGON
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The ruins strengthened the attack!")) if $test_trigger == false
      when :GHOST
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The ruins strengthened the attack!")) if $test_trigger == false
      end
      if target.pbHasType?(:GHOST) && target.hp == target.totalhp
        multipliers[:final_damage_multiplier] /= 2
      end
    when :Garden
      if target.pbHasType?(:BUG)
        multipliers[:defense_multiplier] *= 1.5
      end
      case type
      when :FAIRY, :BUG, :GRASS
        multipliers[:final_damage_multiplier] *= 1.2
        @battle.pbDisplay(_INTL("The garden strengthened the attack!")) if $test_trigger == false
      when :FIRE
        if user.effectiveWeather != :Rain && user.effectiveWeather != :HeavyRain && user.effectiveWeather != :AcidRain
          @battle.pbDisplay(_INTL("The garden caught fire!")) if $test_trigger == false
          $field_effect_bg = "fire"
          $orig_grass = false
          $orig_flying = false
          @battle.scene.pbRefreshEverything
          @battle.field.field_effects = :Fire
          @battle.pbDisplay(_INTL("The field is ablaze.")) if $test_trigger == false
        end
      when :FLYING
        if user.effectiveWeather != :Rain && user.effectiveWeather != :HeavyRain && user.effectiveWeather != :AcidRain
          @battle.pbDisplay(_INTL("The attack kicked up spores!")) if $test_trigger == false
          spore = rand(10)
          spore2 = rand(10)
          if user.status == :NONE
            case spore
            when 0
              user.status = :PARALYSIS
              @battle.pbDisplay(_INTL("{1} was paralyzed!",user.pbThis))
            when 3
              user.status = :POISON
              @battle.pbDisplay(_INTL("{1} was poisoned!",user.pbThis))
            when 6
              user.status = :SLEEP
              @battle.pbDisplay(_INTL("{1} fell asleep!",user.pbThis))
            when 1,2,4,5,7,8,9
              @battle.pbDisplay(_INTL("The spores had no effect on {1}!",user.pbThis)) if $test_trigger == false
            end
          else
            @battle.pbDisplay(_INTL("But {1} was already statused.",user.pbThis)) if $test_trigger == false
          end
          if target.status == :NONE
            case spore2
            when 0
              target.status = :PARALYSIS
              @battle.pbDisplay(_INTL("{1} was paralyzed!",target.pbThis))
            when 3
              target.status = :POISON
              @battle.pbDisplay(_INTL("{1} was poisoned!",target.pbThis))
            when 6
              target.status = :SLEEP
              @battle.pbDisplay(_INTL("{1} fell asleep!",target.pbThis))
            when 1,2,4,5,7,8,9
              @battle.pbDisplay(_INTL("The spores had no effect on {1}!",target.pbThis)) if $test_trigger == false
            end
          else
            @battle.pbDisplay(_INTL("But {1} was already statused.",target.pbThis)) if $test_trigger == false
          end
        end
      end
    end
    # Critical hits
    if target.damageState.critical
      if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
        multipliers[:final_damage_multiplier] *= 1.5
      else
        multipliers[:final_damage_multiplier] *= 2
      end
    end
    # Random variance
    if !self.is_a?(Battle::Move::Confusion)
      random = 85 + @battle.pbRandom(16)
      multipliers[:final_damage_multiplier] *= random / 100.0
    end
    # STAB
    if type && user.pbHasType?(type)
      if user.hasActiveAbility?(:ADAPTABILITY)
        multipliers[:final_damage_multiplier] *= 2
      else
        multipliers[:final_damage_multiplier] *= 1.5
      end
    end
    # Type effectiveness
    multipliers[:final_damage_multiplier] *= target.damageState.typeMod.to_f / Effectiveness::NORMAL_EFFECTIVE
    # Burn
    if user.status == :BURN && physicalMove? && damageReducedByBurn? &&
       !user.hasActiveAbility?(:GUTS)
      multipliers[:final_damage_multiplier] /= 2
    end
    #Frostbite
    if user.status == :FROZEN && specialMove? && damageReducedByFreeze?
      multipliers[:final_damage_multiplier] /= 2
    end
    # Aurora Veil, Reflect, Light Screen
    if !ignoresReflect? && !target.damageState.critical &&
       !user.hasActiveAbility?(:INFILTRATOR)
      if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::Reflect] > 0 && physicalMove?
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::LightScreen] > 0 && specialMove?
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      end
    end
    # Minimize
    if target.effects[PBEffects::Minimize] && tramplesMinimize?
      multipliers[:final_damage_multiplier] *= 2
    end
    # Move-specific base damage modifiers
    multipliers[:base_damage_multiplier] = pbBaseDamageMultiplier(multipliers[:base_damage_multiplier], user, target)
    # Move-specific final damage modifiers
    multipliers[:final_damage_multiplier] = pbModifyDamage(multipliers[:final_damage_multiplier], user, target)
  end
  def pbAdditionalEffectChance(user, target, effectChance = 0)
    return 0 if target.hasActiveAbility?(:SHIELDDUST) && !@battle.moldBreaker
    ret = (effectChance > 0) ? effectChance : @addlEffect
    if (Settings::MECHANICS_GENERATION >= 6 || @function != "EffectDependsOnEnvironment") &&
       (user.hasActiveAbility?(:SERENEGRACE) || user.pbOwnSide.effects[PBEffects::Rainbow] > 0)
      ret *= 2
    end
    ret = 100 if @battle.field.field_effects == :Desert && @function == "BurnTargetSands"
    ret = 100 if $DEBUG && Input.press?(Input::CTRL)
    return ret
  end
end

#Scorching Sands Update for Desert Field
class Battle::Move::BurnTargetSands < Battle::Move
  def canMagicCoat?
    if damagingMove?
      return false
    else
      return true
    end
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanBurn?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbBurn(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute && @battle.field.field_effects != :Desert
    target.pbBurn(user) if target.pbCanBurn?(user, false, self)
  end
end

#Defog Update for Desert Field
class Battle::Move::LowerTargetEvasion1RemoveSideEffects < Battle::Move::TargetStatDownMove
  def ignoresSubstitute?(user); return true; end

  def initialize(battle, move)
    super
    @statDown = [:EVASION, 1]
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    targetSide = target.pbOwnSide
    targetOpposingSide = target.pbOpposingSide
    return false if targetSide.effects[PBEffects::AuroraVeil] > 0 ||
                    targetSide.effects[PBEffects::LightScreen] > 0 ||
                    targetSide.effects[PBEffects::Reflect] > 0 ||
                    targetSide.effects[PBEffects::Mist] > 0 ||
                    targetSide.effects[PBEffects::Safeguard] > 0
    return false if targetSide.effects[PBEffects::StealthRock] ||
                    targetSide.effects[PBEffects::Spikes] > 0 ||
                    targetSide.effects[PBEffects::ToxicSpikes] > 0 ||
                    targetSide.effects[PBEffects::StickyWeb]
    return false if Settings::MECHANICS_GENERATION >= 6 &&
                    (targetOpposingSide.effects[PBEffects::StealthRock] ||
                    targetOpposingSide.effects[PBEffects::Spikes] > 0 ||
                    targetOpposingSide.effects[PBEffects::ToxicSpikes] > 0 ||
                    targetOpposingSide.effects[PBEffects::StickyWeb])
    return false if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None
    return super
  end

  def pbEffectAgainstTarget(user, target)
    if target.pbCanLowerStatStage?(@statDown[0], user, self)
      target.pbLowerStatStage(@statDown[0], @statDown[1], user)
    end
    if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
      target.pbOwnSide.effects[PBEffects::AuroraVeil] = 0
      @battle.pbDisplay(_INTL("{1}'s Aurora Veil wore off!", target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::LightScreen] > 0
      target.pbOwnSide.effects[PBEffects::LightScreen] = 0
      @battle.pbDisplay(_INTL("{1}'s Light Screen wore off!", target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Reflect] > 0
      target.pbOwnSide.effects[PBEffects::Reflect] = 0
      @battle.pbDisplay(_INTL("{1}'s Reflect wore off!", target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Mist] > 0
      target.pbOwnSide.effects[PBEffects::Mist] = 0
      @battle.pbDisplay(_INTL("{1}'s Mist faded!", target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::Safeguard] > 0
      target.pbOwnSide.effects[PBEffects::Safeguard] = 0
      @battle.pbDisplay(_INTL("{1} is no longer protected by Safeguard!!", target.pbTeam))
    end
    if target.pbOwnSide.effects[PBEffects::StealthRock] ||
       (Settings::MECHANICS_GENERATION >= 6 &&
       target.pbOpposingSide.effects[PBEffects::StealthRock])
      target.pbOwnSide.effects[PBEffects::StealthRock]      = false
      target.pbOpposingSide.effects[PBEffects::StealthRock] = false if Settings::MECHANICS_GENERATION >= 6
      @battle.pbDisplay(_INTL("{1} blew away stealth rocks!", user.pbThis))
    end
    if target.pbOwnSide.effects[PBEffects::Spikes] > 0 ||
       (Settings::MECHANICS_GENERATION >= 6 &&
       target.pbOpposingSide.effects[PBEffects::Spikes] > 0)
      target.pbOwnSide.effects[PBEffects::Spikes]      = 0
      target.pbOpposingSide.effects[PBEffects::Spikes] = 0 if Settings::MECHANICS_GENERATION >= 6
      @battle.pbDisplay(_INTL("{1} blew away spikes!", user.pbThis))
    end
    if target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0 ||
       (Settings::MECHANICS_GENERATION >= 6 &&
       target.pbOpposingSide.effects[PBEffects::ToxicSpikes] > 0)
      target.pbOwnSide.effects[PBEffects::ToxicSpikes]      = 0
      target.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0 if Settings::MECHANICS_GENERATION >= 6
      @battle.pbDisplay(_INTL("{1} blew away poison spikes!", user.pbThis))
    end
    if target.pbOwnSide.effects[PBEffects::StickyWeb] ||
       (Settings::MECHANICS_GENERATION >= 6 &&
       target.pbOpposingSide.effects[PBEffects::StickyWeb])
      target.pbOwnSide.effects[PBEffects::StickyWeb]      = false
      target.pbOpposingSide.effects[PBEffects::StickyWeb] = false if Settings::MECHANICS_GENERATION >= 6
      @battle.pbDisplay(_INTL("{1} blew away sticky webs!", user.pbThis))
    end
    if Settings::MECHANICS_GENERATION >= 8 && @battle.field.terrain != :None
      case @battle.field.terrain
      when :Electric
        @battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
      when :Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
      when :Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
      when :Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
      end
      @battle.field.terrain = :None
    end
    case @battle.field.field_effects
    when :Desert
      @battle.field.weather = :Sandstorm
      @battle.field.weatherDuration = user.hasActiveItem?(:SMOOTHROCK) ? 8 : 5
      @battle.pbDisplay(_INTL("The winds kicked up a Sandstorm!"))
    when :ToxicFumes
      @battle.field.field_effects = :None
      $field_effect_bg = "field"
      @battle.scene.pbRefreshEverything
      @battle.pbDisplay(_INTL("The winds cleared up the fumes!"))
    end
  end
end

#Whirlwind Update for Desert Field
class Battle::Move::SwitchOutTargetStatusMove < Battle::Move
  def ignoresSubstitute?(user); return true; end
  def canMagicCoat?;            return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.hasActiveAbility?(:SUCTIONCUPS) && !@battle.moldBreaker
      if show_message
        @battle.pbShowAbilitySplash(target)
        if Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("{1} anchors itself!", target.pbThis))
        else
          @battle.pbDisplay(_INTL("{1} anchors itself with {2}!", target.pbThis, target.abilityName))
        end
        @battle.pbHideAbilitySplash(target)
      end
      return true
    end
    if target.effects[PBEffects::Ingrain]
      @battle.pbDisplay(_INTL("{1} anchored itself with its roots!", target.pbThis)) if show_message
      return true
    end
    if !@battle.canRun
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if @battle.wildBattle? && target.level > user.level
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if @battle.trainerBattle?
      canSwitch = false
      @battle.eachInTeamFromBattlerIndex(target.index) do |_pkmn, i|
        next if !@battle.pbCanSwitchLax?(target.index, i)
        canSwitch = true
        break
      end
      if !canSwitch
        @battle.pbDisplay(_INTL("But it failed!")) if show_message
        return true
      end
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.decision = 3 if @battle.wildBattle?   # Escaped from battle
    if !@battle.wildBattle? && self.type == :FLYING
      case @battle.field.field_effects
      when :Desert
        @battle.field.weather = :Sandstorm
        @battle.field.weatherDuration = user.hasActiveItem?(:SMOOTHROCK) ? 8 : 5
        @battle.pbDisplay(_INTL("The winds kicked up a Sandstorm!"))
      when :ToxicFumes
        @battle.field.field_effects = :None
        $field_effect_bg = "field"
        @battle.scene.pbRefreshEverything
        @battle.pbDisplay(_INTL("The winds cleared up the fumes!"))
      end
    end
  end

  def pbSwitchOutTargetEffect(user, targets, numHits, switched_battlers)
    return if @battle.wildBattle? || !switched_battlers.empty?
    return if user.fainted? || numHits == 0
    targets.each do |b|
      next if b.fainted? || b.damageState.unaffected
      next if b.effects[PBEffects::Ingrain]
      next if b.hasActiveAbility?(:SUCTIONCUPS) && !@battle.moldBreaker
      newPkmn = @battle.pbGetReplacementPokemonIndex(b.index, true)   # Random
      next if newPkmn < 0
      @battle.pbRecallAndReplace(b.index, newPkmn, true)
      @battle.pbDisplay(_INTL("{1} was dragged out!", b.pbThis))
      @battle.pbClearChoice(b.index)   # Replacement Pokémon does nothing this round
      @battle.pbOnBattlerEnteringBattle(b.index)
      switched_battlers.push(b.index)
      break
    end
  end
end

class Battle::Battler
  def pbUseMove(choice, specialUsage = false)
    # NOTE: This is intentionally determined before a multi-turn attack can
    #       set specialUsage to true.
    skipAccuracyCheck = (specialUsage && choice[2] != @battle.struggle)
    # Start using the move
    pbBeginTurn(choice)
    # Force the use of certain moves if they're already being used
    if usingMultiTurnAttack?
      choice[2] = Battle::Move.from_pokemon_move(@battle, Pokemon::Move.new(@currentMove))
      specialUsage = true
    elsif @effects[PBEffects::Encore] > 0 && choice[1] >= 0 &&
          @battle.pbCanShowCommands?(@index)
      idxEncoredMove = pbEncoredMoveIndex
      if idxEncoredMove >= 0 && choice[1] != idxEncoredMove &&
         @battle.pbCanChooseMove?(@index, idxEncoredMove, false)   # Change move if battler was Encored mid-round
        choice[1] = idxEncoredMove
        choice[2] = @moves[idxEncoredMove]
        choice[3] = -1   # No target chosen
      end
    end
    # Labels the move being used as "move"
    move = choice[2]
    return if !move   # if move was not chosen somehow
    # Try to use the move (inc. disobedience)
    @lastMoveFailed = false
    if !pbTryUseMove(choice, move, specialUsage, skipAccuracyCheck)
      @lastMoveUsed     = nil
      @lastMoveUsedType = nil
      if !specialUsage
        @lastRegularMoveUsed   = nil
        @lastRegularMoveTarget = -1
      end
      @battle.pbGainExp   # In case self is KO'd due to confusion
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    move = choice[2]   # In case disobedience changed the move to be used
    return if !move   # if move was not chosen somehow
    # Subtract PP
    if !specialUsage && !pbReducePP(move)
      @battle.pbDisplay(_INTL("{1} used {2}!", pbThis, move.name))
      @battle.pbDisplay(_INTL("But there was no PP left for the move!"))
      @lastMoveUsed          = nil
      @lastMoveUsedType      = nil
      @lastRegularMoveUsed   = nil
      @lastRegularMoveTarget = -1
      @lastMoveFailed        = true
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    # Stance Change
    if isSpecies?(:AEGISLASH) && self.ability == :STANCECHANGE
      if move.damagingMove?
        pbChangeForm(1, _INTL("{1} changed to Blade Forme!", pbThis))
      elsif move.id == :KINGSSHIELD
        pbChangeForm(0, _INTL("{1} changed to Shield Forme!", pbThis))
      end
    end
    # Calculate the move's type during this usage
    move.calcType = move.pbCalcType(self)
    # Start effect of Mold Breaker
    @battle.moldBreaker = hasMoldBreaker?
    # Remember that user chose a two-turn move
    if move.pbIsChargingTurn?(self)
      # Beginning the use of a two-turn attack
      @effects[PBEffects::TwoTurnAttack] = move.id
      @currentMove = move.id
    else
      @effects[PBEffects::TwoTurnAttack] = nil   # Cancel use of two-turn attack
    end
    # Add to counters for moves which increase them when used in succession
    move.pbChangeUsageCounters(self, specialUsage)
    # Charge up Metronome item
    if hasActiveItem?(:METRONOME) && !move.callsAnotherMove?
      if @lastMoveUsed && @lastMoveUsed == move.id && !@lastMoveFailed
        @effects[PBEffects::Metronome] += 1
      else
        @effects[PBEffects::Metronome] = 0
      end
    end
    # Record move as having been used
    @lastMoveUsed     = move.id
    @lastMoveUsedType = move.calcType   # For Conversion 2
    if !specialUsage
      @lastRegularMoveUsed   = move.id   # For Disable, Encore, Instruct, Mimic, Mirror Move, Sketch, Spite
      @lastRegularMoveTarget = choice[3]   # For Instruct (remembering original target is fine)
      @movesUsed.push(move.id) if !@movesUsed.include?(move.id)   # For Last Resort
    end
    @battle.lastMoveUsed = move.id   # For Copycat
    @battle.lastMoveUser = @index   # For "self KO" battle clause to avoid draws
    @battle.successStates[@index].useState = 1   # Battle Arena - assume failure
    # Find the default user (self or Snatcher) and target(s)
    user = pbFindUser(choice, move)
    user = pbChangeUser(choice, move, user)
    targets = pbFindTargets(choice, move, user)
    targets = pbChangeTargets(move, user, targets)
    # Pressure
    if !specialUsage
      targets.each do |b|
        next unless b.opposes?(user) && b.hasActiveAbility?(:PRESSURE)
        PBDebug.log("[Ability triggered] #{b.pbThis}'s #{b.abilityName}")
        user.pbReducePP(move)
      end
      if move.pbTarget(user).affects_foe_side
        @battle.allOtherSideBattlers(user).each do |b|
          next unless b.hasActiveAbility?(:PRESSURE)
          PBDebug.log("[Ability triggered] #{b.pbThis}'s #{b.abilityName}")
          user.pbReducePP(move)
        end
      end
    end
    # Dazzling/Queenly Majesty make the move fail here
    @battle.pbPriority(true).each do |b|
      next if !b || !b.abilityActive?
      if Battle::AbilityEffects.triggerMoveBlocking(b.ability, b, user, targets, move, @battle)
        @battle.pbDisplayBrief(_INTL("{1} used {2}!", user.pbThis, move.name))
        @battle.pbShowAbilitySplash(b)
        @battle.pbDisplay(_INTL("{1} cannot use {2}!", user.pbThis, move.name))
        @battle.pbHideAbilitySplash(b)
        user.lastMoveFailed = true
        pbCancelMoves
        pbEndTurn(choice)
        return
      end
    end
    # "X used Y!" message
    # Can be different for Bide, Fling, Focus Punch and Future Sight
    # NOTE: This intentionally passes self rather than user. The user is always
    #       self except if Snatched, but this message should state the original
    #       user (self) even if the move is Snatched.
    move.pbDisplayUseMessage(self)
    # Snatch's message (user is the new user, self is the original user)
    if move.snatched
      @lastMoveFailed = true   # Intentionally applies to self, not user
      @battle.pbDisplay(_INTL("{1} snatched {2}'s move!", user.pbThis, pbThis(true)))
    end
    # "But it failed!" checks
    if move.pbMoveFailed?(user, targets)
      PBDebug.log(sprintf("[Move failed] In function code %s's def pbMoveFailed?", move.function))
      user.lastMoveFailed = true
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    # Perform set-up actions and display messages
    # Messages include Magnitude's number and Pledge moves' "it's a combo!"
    move.pbOnStartUse(user, targets)
    # Self-thawing due to the move
    if user.status == :FROZEN && move.thawsUser?
      user.pbCureStatus(false)
      @battle.pbDisplay(_INTL("{1} melted the ice!", user.pbThis))
    end
    # Powder
    if user.effects[PBEffects::Powder] && move.calcType == :FIRE
      @battle.pbCommonAnimation("Powder", user)
      @battle.pbDisplay(_INTL("When the flame touched the powder on the Pokémon, it exploded!"))
      user.lastMoveFailed = true
      if ![:Rain, :HeavyRain].include?(user.effectiveWeather) && user.takesIndirectDamage?
        user.pbTakeEffectDamage((user.totalhp / 4.0).round, false) { |hp_lost|
          @battle.pbDisplay(_INTL("{1} is hurt by its {2}!", battler.pbThis, battler.itemName))
        }
        @battle.pbGainExp   # In case user is KO'd by this
      end
      pbCancelMoves
      pbEndTurn(choice)
      return
    end
    # Primordial Sea, Desolate Land
    if move.damagingMove?
      case @battle.pbWeather
      when :HeavyRain
        if move.calcType == :FIRE
          @battle.pbDisplay(_INTL("The Fire-type attack fizzled out in the heavy rain!"))
          user.lastMoveFailed = true
          pbCancelMoves
          pbEndTurn(choice)
          return
        end
      when :HarshSun
        if move.calcType == :WATER
          @battle.pbDisplay(_INTL("The Water-type attack evaporated in the harsh sunlight!"))
          user.lastMoveFailed = true
          pbCancelMoves
          pbEndTurn(choice)
          return
        end
      end
      case @battle.field.field_effects
      when :Lava
        if move.calcType == :WATER
          @battle.pbDisplay(_INTL("The water evaporated!"))
          user.lastMoveFailed = true
          pbCancelMoves
          pbEndTurn(choice)
          return
        end
      end
    end
    # Protean
    if user.hasActiveAbility?([:LIBERO, :PROTEAN]) &&
       !move.callsAnotherMove? && !move.snatched &&
       user.pbHasOtherType?(move.calcType) && !GameData::Type.get(move.calcType).pseudo_type
      @battle.pbShowAbilitySplash(user)
      user.pbChangeTypes(move.calcType)
      typeName = GameData::Type.get(move.calcType).name
      @battle.pbDisplay(_INTL("{1}'s type changed to {2}!", user.pbThis, typeName))
      @battle.pbHideAbilitySplash(user)
      # NOTE: The GF games say that if Curse is used by a non-Ghost-type
      #       Pokémon which becomes Ghost-type because of Protean, it should
      #       target and curse itself. I think this is silly, so I'm making it
      #       choose a random opponent to curse instead.
      if move.function == "CurseTargetOrLowerUserSpd1RaiseUserAtkDef1" && targets.length == 0
        choice[3] = -1
        targets = pbFindTargets(choice, move, user)
      end
    end
    #---------------------------------------------------------------------------
    magicCoater  = -1
    magicBouncer = -1
    if targets.length == 0 && move.pbTarget(user).num_targets > 0 && !move.worksWithNoTargets?
      # def pbFindTargets should have found a target(s), but it didn't because
      # they were all fainted
      # All target types except: None, User, UserSide, FoeSide, BothSides
      @battle.pbDisplay(_INTL("But there was no target..."))
      user.lastMoveFailed = true
    else   # We have targets, or move doesn't use targets
      # Reset whole damage state, perform various success checks (not accuracy)
      @battle.allBattlers.each do |b|
        b.droppedBelowHalfHP = false
        b.statsDropped = false
      end
      targets.each do |b|
        b.damageState.reset
        next if pbSuccessCheckAgainstTarget(move, user, b, targets)
        b.damageState.unaffected = true
      end
      # Magic Coat/Magic Bounce checks (for moves which don't target Pokémon)
      if targets.length == 0 && move.statusMove? && move.canMagicCoat?
        @battle.pbPriority(true).each do |b|
          next if b.fainted? || !b.opposes?(user)
          next if b.semiInvulnerable?
          if b.effects[PBEffects::MagicCoat]
            magicCoater = b.index
            b.effects[PBEffects::MagicCoat] = false
            break
          elsif (b.hasActiveAbility?(:MAGICBOUNCE) || b.hasActiveItem?(:MAGICBOUNCEORB)) && !@battle.moldBreaker &&
                !b.effects[PBEffects::MagicBounce]
            magicBouncer = b.index
            b.effects[PBEffects::MagicBounce] = true
            break
          end
        end
      end
      # Get the number of hits
      numHits = move.pbNumHits(user, targets)
      # Process each hit in turn
      realNumHits = 0
      numHits.times do |i|
        break if magicCoater >= 0 || magicBouncer >= 0
        success = pbProcessMoveHit(move, user, targets, i, skipAccuracyCheck)
        if !success
          if i == 0 && targets.length > 0
            hasFailed = false
            targets.each do |t|
              next if t.damageState.protected
              hasFailed = t.damageState.unaffected
              break if !t.damageState.unaffected
            end
            user.lastMoveFailed = hasFailed
          end
          break
        end
        realNumHits += 1
        break if user.fainted?
        #break if [:SLEEP, :FROZEN].include?(user.status)
        # NOTE: If a multi-hit move becomes disabled partway through doing those
        #       hits (e.g. by Cursed Body), the rest of the hits continue as
        #       normal.
        break if targets.none? { |t| !t.fainted? }   # All targets are fainted
      end
      # Battle Arena only - attack is successful
      @battle.successStates[user.index].useState = 2
      if targets.length > 0
        @battle.successStates[user.index].typeMod = 0
        targets.each do |b|
          next if b.damageState.unaffected
          @battle.successStates[user.index].typeMod += b.damageState.typeMod
        end
      end
      # Effectiveness message for multi-hit moves
      # NOTE: No move is both multi-hit and multi-target, and the messages below
      #       aren't quite right for such a hypothetical move.
      if numHits > 1
        if move.damagingMove?
          targets.each do |b|
            next if b.damageState.unaffected || b.damageState.substitute
            move.pbEffectivenessMessage(user, b, targets.length)
          end
        end
        if realNumHits == 1
          @battle.pbDisplay(_INTL("Hit 1 time!"))
        elsif realNumHits > 1
          @battle.pbDisplay(_INTL("Hit {1} times!", realNumHits))
        end
      end
      # Magic Coat's bouncing back (move has targets)
      targets.each do |b|
        next if b.fainted?
        next if !b.damageState.magicCoat && !b.damageState.magicBounce
        ability = b.ability_id
        if b.hasActiveItem?(:MAGICBOUNCEORB)
          b.ability_id = :MAGICBOUNCE
        end
        @battle.pbShowAbilitySplash(b) if b.damageState.magicBounce
        @battle.pbDisplay(_INTL("{1} bounced the {2} back!", b.pbThis, move.name))
        @battle.pbHideAbilitySplash(b) if b.damageState.magicBounce
        if b.hasActiveItem?(:MAGICBOUNCEORB)
          b.ability_id = ability
        end
        newChoice = choice.clone
        newChoice[3] = user.index
        newTargets = pbFindTargets(newChoice, move, b)
        newTargets = pbChangeTargets(move, b, newTargets)
        success = false
        if !move.pbMoveFailed?(b, newTargets)
          newTargets.each_with_index do |newTarget, idx|
            if pbSuccessCheckAgainstTarget(move, b, newTarget, newTargets)
              success = true
              next
            end
            newTargets[idx] = nil
          end
          newTargets.compact!
        end
        pbProcessMoveHit(move, b, newTargets, 0, false) if success
        b.lastMoveFailed = true if !success
        targets.each { |otherB| otherB.pbFaint if otherB&.fainted? }
        user.pbFaint if user.fainted?
      end
      # Magic Coat's bouncing back (move has no targets)
      if magicCoater >= 0 || magicBouncer >= 0
        mc = @battle.battlers[(magicCoater >= 0) ? magicCoater : magicBouncer]
        if !mc.fainted?
          user.lastMoveFailed = true
          @battle.pbShowAbilitySplash(mc) if magicBouncer >= 0
          @battle.pbDisplay(_INTL("{1} bounced the {2} back!", mc.pbThis, move.name))
          @battle.pbHideAbilitySplash(mc) if magicBouncer >= 0
          success = false
          if !move.pbMoveFailed?(mc, [])
            success = pbProcessMoveHit(move, mc, [], 0, false)
          end
          mc.lastMoveFailed = true if !success
          targets.each { |b| b.pbFaint if b&.fainted? }
          user.pbFaint if user.fainted?
        end
      end
      # Move-specific effects after all hits
      targets.each { |b| move.pbEffectAfterAllHits(user, b) }
      # Faint if 0 HP
      targets.each { |b| b.pbFaint if b&.fainted? }
      user.pbFaint if user.fainted?
      # External/general effects after all hits. Eject Button, Shell Bell, etc.
      pbEffectsAfterMove(user, targets, move, realNumHits)
      @battle.allBattlers.each do |b|
        b.droppedBelowHalfHP = false
        b.statsDropped = false
      end
    end
    # End effect of Mold Breaker
    @battle.moldBreaker = false
    # Gain Exp
    @battle.pbGainExp
    # Battle Arena only - update skills
    @battle.allBattlers.each { |b| @battle.successStates[b.index].updateSkill }
    # Shadow Pokémon triggering Hyper Mode
    pbHyperMode if @battle.choices[@index][0] != :None   # Not if self is replaced
    # End of move usage
    pbEndTurn(choice)
    # Instruct
    @battle.allBattlers.each do |b|
      next if !b.effects[PBEffects::Instruct] || !b.lastMoveUsed
      b.effects[PBEffects::Instruct] = false
      idxMove = -1
      b.eachMoveWithIndex { |m, i| idxMove = i if m.id == b.lastMoveUsed }
      next if idxMove < 0
      oldLastRoundMoved = b.lastRoundMoved
      @battle.pbDisplay(_INTL("{1} used the move instructed by {2}!", b.pbThis, user.pbThis(true)))
      b.effects[PBEffects::Instructed] = true
      if b.pbCanChooseMove?(@moves[idxMove], false)
        PBDebug.logonerr {
          b.pbUseMoveSimple(b.lastMoveUsed, b.lastRegularMoveTarget, idxMove, false)
        }
        b.lastRoundMoved = oldLastRoundMoved
        @battle.pbJudge
        return if @battle.decision > 0
      end
      b.effects[PBEffects::Instructed] = false
    end
    # Dancer
    if !@effects[PBEffects::Dancer] && !user.lastMoveFailed && realNumHits > 0 &&
       !move.snatched && magicCoater < 0 && @battle.pbCheckGlobalAbility(:DANCER) &&
       move.danceMove?
      dancers = []
      @battle.pbPriority(true).each do |b|
        dancers.push(b) if b.index != user.index && b.hasActiveAbility?(:DANCER)
      end
      while dancers.length > 0
        nextUser = dancers.pop
        oldLastRoundMoved = nextUser.lastRoundMoved
        # NOTE: Petal Dance being used because of Dancer shouldn't lock the
        #       Dancer into using that move, and shouldn't contribute to its
        #       turn counter if it's already locked into Petal Dance.
        oldOutrage = nextUser.effects[PBEffects::Outrage]
        nextUser.effects[PBEffects::Outrage] += 1 if nextUser.effects[PBEffects::Outrage] > 0
        oldCurrentMove = nextUser.currentMove
        preTarget = choice[3]
        preTarget = user.index if nextUser.opposes?(user) || !nextUser.opposes?(preTarget)
        @battle.pbShowAbilitySplash(nextUser, true)
        @battle.pbHideAbilitySplash(nextUser)
        if !Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("{1} kept the dance going with {2}!",
                                  nextUser.pbThis, nextUser.abilityName))
        end
        nextUser.effects[PBEffects::Dancer] = true
        if nextUser.pbCanChooseMove?(move, false)
          PBDebug.logonerr {
            nextUser.pbUseMoveSimple(move.id, preTarget)
          }
          nextUser.lastRoundMoved = oldLastRoundMoved
          nextUser.effects[PBEffects::Outrage] = oldOutrage
          nextUser.currentMove = oldCurrentMove
          @battle.pbJudge
          return if @battle.decision > 0
        end
        nextUser.effects[PBEffects::Dancer] = false
      end
    end
  end
end
class Battle::Move::SleepTargetNextTurn < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::Yawn] > 0
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return true if !target.pbCanSleep?(user, true, self)
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::Yawn] = 1
    @battle.pbDisplay(_INTL("{1} made {2} drowsy!", user.pbThis, target.pbThis(true)))
  end
end

class Battle::Move::UserTargetSwapItems < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if !user.item && !target.item
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.unlosableItem?(target.item) ||
       target.unlosableItem?(user.item) ||
       user.unlosableItem?(user.item) ||
       user.unlosableItem?(target.item)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.ability_orb_held?(target.item) || user.ability_orb_held?(user.item) || target.ability_orb_held?(user.item) || user.ability_orb_held?(target.item)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
      if show_message
        @battle.pbShowAbilitySplash(target)
        if Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("But it failed to affect {1}!", target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("But it failed to affect {1} because of its {2}!",
                                  target.pbThis(true), target.abilityName))
        end
        @battle.pbHideAbilitySplash(target)
      end
      return true
    end
    return false
  end
end
class Battle::Move::HealUserFullyAndFallAsleep < Battle::Move::HealingMove
  def pbMoveFailed?(user, targets)
    if user.asleep?
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return true if !user.pbCanSleep?(user, true, self, true)
    @battle.allBattlers.each do |pkmn|
      if pkmn.hasActiveItem?(:CACOPHONYORB) && !pkmn.hasActiveAbility?(:SOUNDPROOF)
        @battle.pbDisplay(_INTL("But the Cacophony kept it awake!"))
        return true
      end
    end
    return true if super
    return false
  end
end

class Battle::Move::CurseTargetOrLowerUserSpd1RaiseUserAtkDef1 < Battle::Move

  def pbEffectAgainstTarget(user, target)
    return if !user.pbHasType?(:GHOST)
    # Ghost effect
    @battle.pbDisplay(_INTL("{1} cut its own HP and laid a curse on {2}!", user.pbThis, target.pbThis(true)))
    target.effects[PBEffects::Curse] = true
    user.effectiveField == :Ruins ? user.pbReduceHP(user.totalhp / 4, false, false) : user.pbReduceHP(user.totalhp / 2, false, false)
    user.pbItemHPHealCheck
  end

end

class Battle::Move::UserTargetSwapItems < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.wild?
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !user.item && !target.item
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.unlosableItem?(target.item) ||
       target.unlosableItem?(user.item) ||
       user.unlosableItem?(user.item) ||
       user.unlosableItem?(target.item)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
      if show_message
        @battle.pbShowAbilitySplash(target)
        if Battle::Scene::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("But it failed to affect {1}!", target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("But it failed to affect {1} because of its {2}!",
                                  target.pbThis(true), target.abilityName))
        end
        @battle.pbHideAbilitySplash(target)
      end
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    oldUserItem = user.item
    oldUserItemName = user.itemName
    oldTargetItem = target.item
    oldTargetItemName = target.itemName
    user.item                             = oldTargetItem
    user.effects[PBEffects::ChoiceBand]   = nil if !user.hasActiveAbility?(:GORILLATACTICS) || !user.hasActiveAbility?(:FORESTSSECRETS)
    user.effects[PBEffects::Unburden]     = (!user.item && oldUserItem) if user.hasActiveAbility?(:UNBURDEN)
    target.item                           = oldUserItem
    target.effects[PBEffects::ChoiceBand] = nil if !target.hasActiveAbility?(:GORILLATACTICS) || !user.hasActiveAbility?(:FORESTSSECRETS)
    target.effects[PBEffects::Unburden]   = (!target.item && oldTargetItem) if target.hasActiveAbility?(:UNBURDEN)
    # Permanently steal the item from wild Pokémon
    if target.wild? && !user.initialItem && oldTargetItem == target.initialItem
      user.setInitialItem(oldTargetItem)
    end
    @battle.pbDisplay(_INTL("{1} switched items with its opponent!", user.pbThis))
    @battle.pbDisplay(_INTL("{1} obtained {2}.", user.pbThis, oldTargetItemName)) if oldTargetItem
    @battle.pbDisplay(_INTL("{1} obtained {2}.", target.pbThis, oldUserItemName)) if oldUserItem
    user.pbHeldItemTriggerCheck
    target.pbHeldItemTriggerCheck
  end
end

#Polarity Pulse
class Battle::Move::SuperEffectiveAgainstElectric < Battle::Move
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :ELECTRIC
    return super
  end
end

#Ancient Cry
class Battle::Move::EffectiveAgainstFairy < Battle::Move
  def pbCalcTypeModSingle(moveType,defType,user,target)
    return Effectiveness::NORMAL_EFFECTIVE_ONE if defType == :FAIRY
    return super
  end
end

#Grassy Glide to boost priority in Garden field
class Battle::Move::HigherPriorityInGrassyTerrain < Battle::Move
  def pbPriority(user)
    ret = super
    ret += 1 if @battle.field.terrain == :Grassy && user.affectedByTerrain?
    ret += 1 if @battle.field.field_effects == :Garden && user.affectedByGarden?
    return ret
  end
end

class Battle::Move::UseMoveDependingOnEnvironment < Battle::Move
  def callsAnotherMove?; return true; end

  def pbOnStartUse(user, targets)
    # NOTE: It's possible in theory to not have the move Nature Power wants to
    #       turn into, but what self-respecting game wouldn't at least have Tri
    #       Attack in it?
    @npMove = :TRIATTACK
    case @battle.field.terrain
    when :Electric
      @npMove = :THUNDERBOLT if GameData::Move.exists?(:THUNDERBOLT)
    when :Grassy
      @npMove = :ENERGYBALL if GameData::Move.exists?(:ENERGYBALL)
    when :Misty
      @npMove = :MOONBLAST if GameData::Move.exists?(:MOONBLAST)
    when :Psychic
      @npMove = :PSYCHIC if GameData::Move.exists?(:PSYCHIC)
    else
      case @battle.field.field_effects
      when :Garden
        @npMove = :PETALDANCE if GameData::Move.exists?(:PETALDANCE)
      when :City
        @npMove = :OVERDRIVE if GameData::Move.exists?(:OVERDRIVE)
      when :Ruins
        @npMove = :ANCIENTPOWER if GameData::Move.exists?(:ANCIENTPOWER)
      when :Swamp
        @npMove = :MUDDYWATER if GameData::Move.exists?(:MUDDYWATER)
      else
        try_move = nil
        case @battle.environment
        when :Grass, :TallGrass, :Forest, :ForestGrass
          try_move = (Settings::MECHANICS_GENERATION >= 6) ? :ENERGYBALL : :SEEDBOMB
        when :MovingWater, :StillWater, :Underwater
          try_move = :HYDROPUMP
        when :Puddle
          try_move = :MUDBOMB
        when :Cave
          try_move = (Settings::MECHANICS_GENERATION >= 6) ? :POWERGEM : :ROCKSLIDE
        when :Rock, :Sand
          try_move = (Settings::MECHANICS_GENERATION >= 6) ? :EARTHPOWER : :EARTHQUAKE
        when :Snow
          try_move = :BLIZZARD
          try_move = :FROSTBREATH if Settings::MECHANICS_GENERATION == 6
          try_move = :ICEBEAM if Settings::MECHANICS_GENERATION >= 7
        when :Ice
          try_move = :ICEBEAM
        when :Volcano
          try_move = :LAVAPLUME
        when :Graveyard
          try_move = :SHADOWBALL
        when :Sky
          try_move = :AIRSLASH
        when :Space
          try_move = :DRACOMETEOR
        when :UltraSpace
          try_move = :PSYSHOCK
        end
        @npMove = try_move if GameData::Move.exists?(try_move)
      end
    end
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbDisplay(_INTL("{1} turned into {2}!", @name, GameData::Move.get(@npMove).name))
    user.pbUseMoveSimple(@npMove, target.index)
  end
end

class Battle::Move::RaiseUserSpAtk1Spd2 < Battle::Move::MultiStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPEED, 2, :SPECIAL_ATTACK, 1]
  end
end

class Battle::Move::RaiseUserAcc2AlwaysCrit < Battle::Move::StatUpMove
  def initialize(battle, move)
    super
    @statUp = [:ACCURACY,2]
  end

  def pbEffectGeneral(user)
    super
    user.effects[PBEffects::CaennerbongDance] = true
  end
end

class Battle::Move::EndBattle < Battle::Move
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    @battle.pbDisplay(_INTL("You just got rekt!"))
    SaveData.delete_file
    raise SystemExit.new
  end
end