class PBAI
  class ScoreHandler
    @@GeneralCode = []
    @@MoveCode = {}
    @@StatusCode = []
    @@DamagingCode = []

    def self.add_status(&code)
      @@StatusCode << code
    end

    def self.add_damaging(&code)
      @@DamagingCode << code
    end

    def self.add(*moves, &code)
      if moves.size == 0
        @@GeneralCode << code
      else
        moves.each do |move|
          if move.is_a?(Symbol) # Specific move
            id = getConst(Battle::Move, move)
            raise "Invalid move #{move}" if id.nil? || id == 0
            @@MoveCode[id] = code
          elsif move.is_a?(String) # Function code
            @@MoveCode[move] = code
          end
        end
      end
    end

    def self.trigger(list, score, ai, user, target, move)
      return score if list.nil?
      list = [list] if !list.is_a?(Array)
      $test_trigger = true
      list.each do |code|
        next if code.nil?
        newscore = code.call(score, ai, user, target, move)
        score = newscore if newscore.is_a?(Numeric)
      end
      $test_trigger = false
      return score
    end

    def self.trigger_general(score, ai, user, target, move)
      return self.trigger(@@GeneralCode, score, ai, user, target, move)
    end

    def self.trigger_status_moves(score, ai, user, target, move)
      return self.trigger(@@StatusCode, score, ai, user, target, move)
    end

    def self.trigger_damaging_moves(score, ai, user, target, move)
      return self.trigger(@@DamagingCode, score, ai, user, target, move)
    end

    def self.trigger_move(move, score, ai, user, target)
      id = move.id
      id = move.function if !@@MoveCode[id]
      return self.trigger(@@MoveCode[id], score, ai, user, target, move)
    end
  end
end

#=============================================================================#
#                                                                             #
# Multipliers                                                                 #
#                                                                             #
#=============================================================================#


# Effectiveness modifier
# For this to have a more dramatic effect, this block could be moved lower down
# so that it factors in more score modifications before multiplying.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  # Effectiveness doesn't add anything for fixed-damage moves.
  next if move.is_a?(Battle::Move::FixedDamageMove) || move.statusMove?
  # Add half the score times the effectiveness modifiers. Means super effective
  # will be a 50% increase in score.
  target_types = target.types
  mod = move.pbCalcTypeMod(move.type, user, target) / Effectiveness::NORMAL_EFFECTIVE.to_f
  # If mod is 0, i.e. the target is immune to the move (based on type, at least),
  # we do not multiply the score to 0, because immunity is handled as a final multiplier elsewhere.
  if mod != 0 && mod != 1
    score *= mod
    PBAI.log("* #{mod} for effectiveness")
  end
  next score
end



#=============================================================================#
#                                                                             #
# All Moves                                                                   #
#                                                                             #
#=============================================================================#


# Accuracy modifier to favor high-accuracy moves
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  next if user.battler == target.battler
  accuracy = user.get_move_accuracy(move, target)
  missing = 100 - accuracy
  # (High) Jump Kick, a move that damages you when you miss
  if move.function == "CrashDamageIfFailsUnusableInGravity"
    # Decrease the score more drastically if it has lower accuracy
    missing *= 2.0
  end
  if missing > 0
    score -= missing
    PBAI.log("- #{missing} for accuracy")
  end
  next score
end


# Increase/decrease score for each positive/negative stat boost the move gives the user
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  next if !move.is_a?(Battle::Move::MultiStatUpMove) && !move.is_a?(Battle::Move::StatUpMove) &&
          !move.is_a?(Battle::Move::StatDownMove)
  boosts = 0
  atkBoosts = 0
  spAtkBoosts = 0
  evBoosts = 0
  stats = []
  if move.statUp
    for i in 0...move.statUp.size / 2
      stat = move.statUp[i * 2]
      incr = move.statUp[i * 2 + 1]
      boosts += incr
      atkBoosts += incr if stat == :ATTACK
      spAtkBoosts += incr if stat == :SPECIAL_ATTACK
      evBoosts += incr if stat == :EVASION
      stats << stat
    end
  end
  if move.statDown
    for i in 0...move.statDown.size / 2
      stat = move.statDown[i * 2]
      decr = move.statDown[i * 2 + 1]
      boosts -= decr if
      atkBoosts -= decr if stat == :ATTACK
      spAtkBoosts -= decr if stat == :SPECIAL_ATTACK
      stats << stat if !stats.include?(stat)
    end
  end
  # Increase score by 10 * (net stage differences)
  # If attack is boosted and the user is a physical attacker,
  # these stage increases are multiplied by 20 instead of 10.
  if atkBoosts > 0 && user.is_physical_attacker?
    atkIncr = (atkBoosts * 30 * (2 - (user.stages[:ATTACK] + 6) / 6.0)).round
    if atkIncr > 0
      score += atkIncr
      PBAI.log("+ #{atkIncr} for attack boost and being a physical attacker")
      boosts -= atkBoosts
    end
  end
  # If spatk is boosted and the user is a special attacker,
  # these stage increases are multiplied by 20 instead of 10.
  if spAtkBoosts > 0 && user.is_special_attacker?
    spatkIncr = (spAtkBoosts * 30 * (2 - (user.stages[:SPECIAL_ATTACK] + 6) / 6.0)).round
    if spatkIncr > 0
      score += spatkIncr
      PBAI.log("+ #{spatkIncr} for spatk boost and being a special attacker")
      boosts -= spAtkBoosts
    end
  end
  # Boost to evasion
  if evBoosts != 0
    evIncr = (evBoosts * 50 * (2 - (user.stages[:EVASION] + 6) / 6.0)).round
    if evIncr > 0
      score += evIncr
      PBAI.log("+ #{evIncr} for evasion boost")
      boosts -= evBoosts
    end
  end
  # All remaining stat increases (or decreases) are multiplied by 25 and added to the score.
  if boosts != 0
    total = 6 * stats.size
    eff = total
    user.stages.each_with_index do |value, stage|
      if stats.include?(stage)
        eff -= value
      end
    end
    fact = 1.0
    fact = eff / total.to_f if total != 0
    incr = (boosts * 25 * fact).round
    if incr > 0
      score += incr
      PBAI.log("+ #{incr} for general user buffs (#{eff}/#{total} effectiveness)")
    end
  end
  next score
end


# Increase/decrease score for each positive/negative stat boost the move gives the target
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  next if !move.is_a?(Battle::Move::TargetStatDownMove) && !move.is_a?(Battle::Move::TargetMultiStatDownMove)
  debuffs = 0
  accDecreases = 0
  stats = []
  if move.statDown
    for i in 0...move.statDown.size / 2
      stat = move.statDown[i * 2]
      decr = move.statDown[i * 2 + 1]
      debuffs += decr
      accDecreases += decr if stat == :ACCURACY
      stats << stat if stat != :EVASION && stat != :ACCURACY
    end
  end
  if accDecreases != 0 && target.stages[:ACCURACY] != -6
    accIncr = (accDecreases * 50 * (target.stages[:ACCURACY] + 6) / 6.0).round
    score += accIncr
    debuffs -= accIncr
    PBAI.log("+ #{accIncr} for target accuracy debuff")
  end
  # All remaining stat decrases are multiplied by 10 and added to the score.
  if debuffs > 0
    total = 6 * stats.size
    eff = total
    target.stages.each_with_index do |value, stage|
      if stats.include?(stage)
        eff += value
      end
    end
    fact = 1.0
    fact = eff / total.to_f if total != 0
    incr = (debuffs * 25 * fact).round
    score += incr
    PBAI.log("+ #{incr} for general target debuffs (#{eff}/#{total} effectiveness)")
  end
  next score
end


# Prefer priority moves that deal enough damage to knock the target out.
# Use previous damage dealt to determine if it deals enough damage now,
# or make a rough estimate.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  # Apply this logic only for priority moves
  next if move.priority <= 0 || move.function == "MultiTurnAttackBideThenReturnDoubleDamage" # Bide
  prevDmg = target.get_damage_by_user_and_move(user, move)
  if prevDmg.size > 0 && prevDmg != 0
    # We have the previous damage this user has done with this move.
    # Use the average of the previous damage dealt, and if it's more than the target's hp,
    # we can likely use this move to knock out the target.
    avg = (prevDmg.map { |e| e[2] }.sum / prevDmg.size.to_f).floor
    if avg >= target.battler.hp
      PBAI.log("+ 250 for priority move with average damage (#{avg}) >= target hp (#{target.battler.hp})")
      score += 250
    end
  else
    # Calculate the damage this priority move will do.
    # The AI kind of cheats here, because this takes all items, berries, abilities, etc. into account.
    # It is worth for the effect though; the AI using a priority move to prevent
    # you from using one last move before you faint.
    dmg = user.get_move_damage(target, move)
    if dmg >= target.battler.hp
      PBAI.log("+ 250 for priority move with predicted damage (#{dmg}) >= target hp (#{target.battler.hp})")
      score += 250
    end
  end
  if target.hp <= target.totalhp/4
    score += 100
    PBAI.log("+ 100 for attempting to kill the target with priority")
  end
  if user.hp <= user.totalhp/4 && target.faster_than?(user)
    score += 100
    PBAI.log("+ 100 for attempting to do last minute damage to the target with priority")
  end
  if user.turnCount > 0 && move.function == "FlinchTargetFailsIfNotUserFirstTurn"
    score = 0
    PBAI.log("* 0 to prevent Fake Out failing")
  end
  next score
end


# Encourage using fixed-damage moves if the fixed damage is more than the target has HP
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  next if !move.is_a?(Battle::Move::FixedDamageMove) || move.function == "OHKO" || move.function == "MultiTurnAttackBideThenReturnDoubleDamage"
  dmg = move.pbFixedDamage(user, target)
  if dmg >= target.hp
    score += 175
    PBAI.log("+ 175 for this move's fixed damage being enough to knock out the target")
  end
  next score
end


# See if any moves used in the past did enough damage to now kill the target,
# and if so, give that move slightly more preference.
# There can be more powerful moves that might also take out the user,
# but if this move will also take the user out, this is a safer option.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  next if move.function == "MultiTurnAttackBideThenReturnDoubleDamage" # Bide
  # Get all times this move was used on the target
  ary = target.get_damage_by_user_and_move(user, move)
  # If this move has been used before, and the move is not a two-turn move
  if ary != 0 && ary.size > 0 && !move.chargingTurnMove? && move.function != "AttackAndSkipNextTurn" # Hyper Beam
    # Calculate the average damage of every time this move was used on the target
    avg = ary.map { |e| e[2] }.sum / ary.size.to_f
    # If the average damage this move dealt is enough to kill the target, increase likelihood of choosing this move
    if avg >= target.hp
      score += 100
      PBAI.log("+ 100 for this move being likely to take out the target")
    end
  end
  next score
end


# Prefer moves that are usable while the user is asleep
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  # If the move is usable while asleep, and if the user won't wake up this turn
  # Kind of cheating, but insignificant. This way the user can choose a more powerful move instead
  if move.usableWhenAsleep?
    if user.asleep? && user.statusCount > 1
      score += 200
      PBAI.log("+ 200 for being able to use this move while asleep")
    else
      score -= 50
      PBAI.log("- 50 for this move will have no effect")
    end
  end
  next score
end


# Prefer moves that can thaw the user if the user is frozen
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  # If the user is frozen and the move thaws the user
  if user.frozen? && move.thawsUser?
    score += 80
    PBAI.log("+ 80 for being able to thaw the user")
  end
  next score
end


# Discourage using OHKO moves if the target is higher level or it has sturdy
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.function == "OHKO" # OHKO Move
    if target.has_ability?(:STURDY)
      score -= 100
      PBAI.log("- 100 for the target has Sturdy")
    end
    if target.level > user.level
      score -= 80
      PBAI.log("- 80 for the move will fail due to level difference")
    end
    score -= 50
    PBAI.log("- 50 for OHKO moves are generally considered bad")
  end
  next score
end


# Encourage using trapping moves, since they're generally weak
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.function == "BindTarget" # Trapping Move
    if target.effects[PBEffects::Trapping] == 0 # The target is not yet trapped
      score += 60
      PBAI.log("+ 60 for initiating a multi-turn trap")
    end
  end
  next score
end


# Encourage using flinching moves if the user is faster
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.flinchingMove? && (user.faster_than?(target) || move.priority > 0)
    score += 50
    PBAI.log("+ 50 for being able to flinch the target")
    if user.turnCount == 0 && move.function == "FlinchTargetFailsIfNotUserFirstTurn"
      score += 500
      PBAI.log("+ 500 for using Fake Out turn 1")
      if ai.battle.pbSideSize(0) == 2
        score += 200
        PBAI.log("+ 200 for being in a Double battle")
      end
    elsif user.turnCount != 0 && move.function == "FlinchTargetFailsIfNotUserFirstTurn"
      score -= 90
      PBAI.log("- 90 to stop Fake Out beyond turn 1")
    end
  end
  next score
end


# Discourage using a multi-hit physical move if the target has an item or ability
# that will damage the user on each contact.
# Also slightly discourages physical moves if the target has a bad ability in general.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.pbContactMove?(user)
    if user.discourage_making_contact_with?(target)
      if move.multiHitMove?
        score -= 60
        PBAI.log("- 60 for the target has an item or ability that activates on each contact")
      else
        score -= 30
        PBAI.log("- 30 for the target has an item or ability that activates on contact")
      end
    end
  end
  next score
end


# Encourage using moves that can cause a burn.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::BurnTarget) && !target.burned? && target.can_burn?(user, move)
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      if target.is_physical_attacker?
        add = 30 + chance * 2
        score += add
        PBAI.log("+ #{add} for being able to burn the physical-attacking target")
      else
        score += chance
        PBAI.log("+ #{chance} for being able to burn the target")
      end
    end
  end
  next score
end

#Remove a move as a possible choice if not the one Choice locked into
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if user.effects[PBEffects::ChoiceBand]
    choiced_move = user.effects[PBEffects::ChoiceBand]
    if choiced_move == move.id
      score += 500
      PBAI.log("+ 500 for being Choice locked")
      if !user.can_switch?
        score += 1000
        PBAI.log("+ 1000 for being Choice locked and unable to switch")
      end
    else
      score -= 100
      PBAI.log("- 100 for being Choice locked")
    end
  end
  next score
end


# Encourage using moves that can cause freezing.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::FreezeTarget) && !target.frozen? && target.can_freeze?(user, move)
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      score += chance * 2
      PBAI.log("+ #{chance} for being able to freeze the target")
    end
  end
  next score
end


# Encourage using moves that can cause paralysis.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::ParalyzeTarget) && !target.paralyzed? && target.can_paralyze?(user, move)
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      score += chance
      PBAI.log("+ #{chance} for being able to paralyze the target")
    end
    if user.role.id == :SPEEDCONTROL
      score += 100
      PBAI.log("+ 100 for being #{user.role.name}")
    end
  end
  next score
end


# Encourage using moves that can cause sleep.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::SleepTarget) && !target.asleep? && target.can_sleep?(user, move)
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      score += chance
      PBAI.log("+ #{chance} for being able to put the target to sleep")
    end
  end
  next score
end


# Encourage using moves that can cause poison.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::PoisonTarget) && !target.poisoned? && target.can_poison?(user, move)
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      if move.toxic
        add = chance * 1.4 * move.pbNumHits(user, [target])
        score += add
        PBAI.log("+ #{add} for being able to badly poison the target")
      else
        add = chance * move.pbNumHits(user, [target])
        score += add
        PBAI.log("+ #{add} for being able to poison the target")
      end
    end
  end
  next score
end


# Encourage using moves that can cause confusion.
PBAI::ScoreHandler.add do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::ConfuseTarget) && !target.confused?
    chance = move.pbAdditionalEffectChance(user, target)
    chance = 100 if chance == 0
    if chance > 0 && chance <= 100
      add = chance * move.pbNumHits(user, [target])
      # The higher the target's attack stats, the more beneficial it is to confuse the target.
      stageMul = [2,2,2,2,2,2, 2, 3,4,5,6,7,8]
      stageDiv = [8,7,6,5,4,3, 2, 2,2,2,2,2,2]
      stage = target.stages[:ATTACK] + 6
      factor = stageMul[stage] / stageDiv[stage].to_f
      add *= factor
      score += add
      PBAI.log("+ #{add} for being able to confuse the target")
    end
  end
  next score
end


#=============================================================================#
#                                                                             #
# Damaging Moves                                                              #
#                                                                             #
#=============================================================================#


# STAB modifier
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  # STAB doesn't add anything for fixed-damage moves.
  next if move.is_a?(Battle::Move::FixedDamageMove)
  calcType = move.pbCalcType(user.battler)
  if calcType != nil && user.has_type?(calcType)
    if user.has_ability?(:ADAPTABILITY)
      PBAI.log("+ 90 for STAB with Adaptability")
      score += 90
    else
      PBAI.log("+ 50 for STAB")
      score += 50
    end
  end
  next score
end


# Stat stages and physical/special attacker label
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  # Stat boosts don't add anything for fixed-damage moves.
  next if move.is_a?(Battle::Move::FixedDamageMove)
  # If the move is physical
  if move.physicalMove?
    # Increase the score by 25 per stage increase/decrease
    if user.stages[:ATTACK] != 0
      add = user.stages[:ATTACK] * 25
      score += add
      PBAI.log("#{add < 0 ? "-" : "+"} #{add.abs} for attack stages")
    end
    # Make the move more likely to be chosen if this user is also considered a physical attacker.
    if user.is_physical_attacker?
      score += 30
      PBAI.log("+ 30 for being a physical attacker")
    end
  end

  # If the move is special
  if move.specialMove?
    # Increase the score by 25 per stage increase/decrease
    if user.stages[:SPECIAL_ATTACK] != 0
      add = user.stages[:SPECIAL_ATTACK] * 25
      score += add
      PBAI.log("#{add < 0 ? "-" : "+"} #{add.abs} for attack stages")
    end
    # Make the move more likely to be chosen if this user is also considered a special attacker.
    if user.is_special_attacker?
      score += 30
      PBAI.log("+ 30 for being a special attacker")
    end
  end
  next score
end


# Discourage using damaging moves if the target is semi-invulnerable and slower,
# and encourage using damaging moves if they can break through the semi-invulnerability
# (e.g. prefer earthquake when target is underground)
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  # Target is semi-invulnerable
  if target.semiInvulnerable? || target.effects[PBEffects::SkyDrop] >= 0
    encourage = false
    discourage = false
    # User will hit first while target is still semi-invulnerable.
    # If this move will do extra damage because the target is semi-invulnerable,
    # encourage using this move. If not, discourage using it.
    if user.faster_than?(target)
      if target.in_two_turn_attack?("TwoTurnAttackInvulnerableInSky", "TwoTurnAttackInvulnerableInSkyParalyzeTarget", "TwoTurnAttackInvulnerableInSkyTargetCannotAct") # Fly, Bounce, Sky Drop
        encourage = move.hitsFlyingTargets?
        discourage = !encourage
      elsif target.in_two_turn_attack?("TwoTurnAttackInvulnerableUnderground") # Dig
        # Do not encourage using Fissure, even though it can hit digging targets, because it's an OHKO move
        encourage = move.hitsDiggingTargets? && move.function != "OHKOHitsUndergroundTarget"
        discourage = !encourage
      elsif target.in_two_turn_attack?("TwoTurnAttackInvulnerableUnderwater") # Dive
        encourage = move.hitsDivingTargets?
        discourage = !encourage
      else
        discourage = true
      end
    end
    # If the user has No Guard
    if user.has_ability?(:NOGUARD)
      # Then any move would be able to hit the target, meaning this move wouldn't be anything special.
      encourage = false
      discourage = false
    end
    if encourage
      score += 100
      PBAI.log("+ 100 for being able to hit through a semi-invulnerable state")
    elsif discourage
      score -= 150
      PBAI.log("- 150 for not being able to hit target because of semi-invulnerability")
    end
  end
  next score
end


# Lower the score of multi-turn moves, because they likely have quite high power and thus score.
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  if !user.has_item?(:POWERHERB) && (move.chargingTurnMove? || move.function == "AttackAndSkipNextTurn") # Hyper Beam
    score -= 70
    PBAI.log("- 70 for requiring a charging turn")
  end
  next score
end


# Prefer using damaging moves based on the level difference between the user and target,
# because if the user will get one-shot, then there's no point in using set-up moves.
# Furthermore, if the target is more than 5 levels higher than the user, priority
# get an additional boost to ensure the user can get a hit in before being potentially one-shot.
# TODO: Make "underdog" method, also for use by moves like perish song or explode and such
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  # Start counting factor this when there's a level difference of greater than 5
  if user.underdog?(target)
    add = 5 * (target.level - user.level - 5)
    if add > 0
      score += add
      PBAI.log("+ #{5 * (target.level - user.level - 5)} for preferring damaging moves due to being a low level")
    end
    if move.priority > 0
      score += 30
      PBAI.log("+ 30 for being a priority move and being and underdog")
    end
  end
  next score
end

PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  # Start counting factor this when there's a level difference of greater than 5
  dmg = user.get_move_damage(target, move)
  if move.priority > 0 && dmg >= target.battler.hp
    score += 90
    PBAI.log("+ 90 for being a priority move and being able to KO the opponent")
  end
  next score
end
# Discourage using physical moves when the user is burned
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  if user.burned?
    if move.physicalMove? && move.function != "DoublePowerIfUserPoisonedBurnedParalyzed"
      score -= 50
      PBAI.log("- 50 for being a physical move and being burned")
    end
  end
  next score
end


# Encourage high-critical hit rate moves, or damaging moves in general
# if Laser Focus or Focus Energy has been used
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  next if !move.pbCouldBeCritical?(user.battler, target.battler)
  if move.highCriticalRate? || user.effects[PBEffects::LaserFocus] > 0 ||
     user.effects[PBEffects::FocusEnergy] > 0
    score += 30
    PBAI.log("+ 30 for having a high critical-hit rate")
  end
  next score
end


# Discourage recoil moves if they would knock the user out
PBAI::ScoreHandler.add_damaging do |score, ai, user, target, move|
  if move.is_a?(Battle::Move::RecoilMove)
    dmg = move.pbRecoilDamage(user.battler, target.battler)
    if dmg >= user.hp
      score -= 50
      PBAI.log("- 50 for the recoil will knock the user out")
    end
  end
  next score
end



#=============================================================================#
#                                                                             #
# Move-specific                                                               #
#                                                                             #
#=============================================================================#


# Facade
PBAI::ScoreHandler.add("DoublePowerIfUserPoisonedBurnedParalyzed") do |score, ai, user, target, move|
  if user.burned? || user.poisoned? || user.paralyzed? || user.frozen?
    score += 50
    PBAI.log("+ 50 for doing more damage with a status condition")
  end
  next score
end


# Aromatherapy, Heal Bell
PBAI::ScoreHandler.add("CureUserPartyStatus") do |score, ai, user, target, move|
  count = 0
  user.side.battlers.each do |proj|
    next if proj.nil?
    # + 80 for each active battler with a status condition
    count += 2.0 if proj.has_non_volatile_status?
  end
  user.side.party.each do |proj|
    next if proj.battler # Skip battlers
    # Inactive party members do not have a battler attached,
    # so we can't use has_non_volatile_status?
    count += 1.0 if proj.pokemon.status > 0
    # + 40 for each inactive pokemon with a status condition in the party
  end
  if count != 0
    add = count * 40.0
    score += add
    PBAI.log("+ #{add} for curing status condition(s)")
  else
    score -= 30
    PBAI.log("- 30 for not curing any status conditions")
  end
  next score
end


# Psycho Shift
PBAI::ScoreHandler.add("GiveUserStatusToTarget") do |score, ai, user, target, move|
  if user.has_non_volatile_status?
    # And the target doesn't have any status conditions
    if !target.has_non_volatile_status?
      # Then we can transfer our status condition
      transferrable = true
      transferrable = false if user.burned? && !target.can_burn?(user, move)
      transferrable = false if user.poisoned? && !target.can_poison?(user, move)
      transferrable = false if user.paralyzed? && !target.can_paralyze?(user, move)
      transferrable = false if user.asleep? && !target.can_sleep?(user, move)
      transferrable = false if user.frozen? && !target.can_freeze?(user, move)
      if transferrable
        score += 120
        PBAI.log("+ 120 for being able to pass on our status condition")
        if user.burned? && target.is_physical_attacker?
          score += 50
          PBAI.log("+ 50 for being able to burn the physical-attacking target")
        end
        if user.frozen? && target.is_special_attacker?
          score += 50
          PBAI.log("+ 50 for being able to frostbite the special-attacking target")
        end
      end
    end
  else
    score -= 30
    PBAI.log("- 30 for not having a transferrable status condition")
  end
  next score
end


# Purify
PBAI::ScoreHandler.add("CureTargetStatusHealUserHalfOfTotalHP") do |score, ai, user, target, move|
  if target.has_non_volatile_status?
    factor = 1 - user.hp / user.totalhp.to_f
    # At full hp, factor is 0 (thus not encouraging this move)
    # At half hp, factor is 0.5 (thus slightly encouraging this move)
    # At 1 hp, factor is about 1.0 (thus encouraging this move)
    if factor != 0
      if user.is_healing_pointless?(0.5)
        score -= 10
        PBAI.log("- 10 for we will take more damage than we can heal if the target repeats their move")
      elsif user.is_healing_necessary?(0.5)
        add = (factor * 250).round
        score += add
        PBAI.log("+ #{add} for we will likely die without healing")
      else
        add = (factor * 125).round
        score += add
        PBAI.log("+ #{add} for we have lost some hp")
      end
    end
  else
    score -= 30
    PBAI.log("- 30 for the move will fail since the target has no status condition")
  end
  next score
end


# Refresh
PBAI::ScoreHandler.add("CureUserBurnPoisonParalysis") do |score, ai, user, target, move|
  if user.burned? || user.poisoned? || user.paralyzed?
    score += 70
    PBAI.log("+ 70 for being able to cure our status condition")
  end
  next score
end


# Rest
PBAI::ScoreHandler.add("HealUserFullyAndFallAsleep") do |score, ai, user, target, move|
  factor = 1 - user.hp / user.totalhp.to_f
  if factor != 0
    # Not at full hp
    if user.can_sleep?(user, move, true)
      add = (factor * 100).round
      score += add
      PBAI.log("+ #{add} for we have lost some hp")
    else
      score -= 10
      PBAI.log("- 10 for the move will fail")
    end
  end
  next score
end


# Smelling Salts
PBAI::ScoreHandler.add("DoublePowerIfTargetParalyzedCureTarget") do |score, ai, user, target, move|
  if target.paralyzed?
    score += 50
    PBAI.log("+ 50 for doing double damage")
  end
  next score
end


# Wake-Up Slap
PBAI::ScoreHandler.add("DoublePowerIfTargetAsleepCureTarget") do |score, ai, user, target, move|
  if target.asleep?
    score += 50
    PBAI.log("+ 50 for doing double damage")
  end
  next score
end


# Fire Fang, Flare Blitz
PBAI::ScoreHandler.add("BurnFlinchTarget", "RecoilThirdOfDamageDealtBurnTarget") do |score, ai, user, target, move|
  if !target.burned? && target.can_burn?(user, move)
    if target.is_physical_attacker?
      score += 40
      PBAI.log("+ 40 for being able to burn the physical-attacking target")
    else
      score += 10
      PBAI.log("+ 10 for being able to burn the target")
    end
  end
  next score
end


# Ice Fang
PBAI::ScoreHandler.add("FreezeFlinchTarget") do |score, ai, user, target, move|
  if !target.frozen? && target.can_freeze?(user, move)
    score += 20
    PBAI.log("+ 20 for being able to freeze the target")
  end
  next score
end


# Thunder Fang
PBAI::ScoreHandler.add("ParalyzeFlinchTarget") do |score, ai, user, target, move|
  if !target.paralyzed? && target.can_paralyze?(user, move)
    score += 10
    PBAI.log("+ 10 for being able to paralyze the target")
  end
  next score
end


# Ice Burn
PBAI::ScoreHandler.add("TwoTurnAttackBurnTarget") do |score, ai, user, target, move|
  if !target.burned? && target.can_burn?(user, move)
    if target.is_physical_attacker?
      score += 80
      PBAI.log("+ 80 for being able to burn the physical-attacking target")
    else
      score += 30
      PBAI.log("+ 30 for being able to burn the target")
    end
  end
  next score
end


# Secret Power
PBAI::ScoreHandler.add("EffectDependsOnEnvironment") do |score, ai, user, target, move|
  score += 40
  PBAI.log("+ 40 for its potential side effects")
  next score
end


# Tri Attack
PBAI::ScoreHandler.add("ParalyzeBurnOrFreezeTarget") do |score, ai, user, target, move|
  if !target.has_non_volatile_status?
    score += 50
    PBAI.log("+ 50 for being able to cause a status condition")
  end
  next score
end


# Freeze Shock, Bounce
PBAI::ScoreHandler.add("TwoTurnAttackParalyzeTarget", "TwoTurnAttackInvulnerableInSkyParalyzeTarget") do |score, ai, user, target, move|
  if !target.paralyzed? && target.can_paralyze?(user, move)
    score += 30
    PBAI.log("+ 30 for being able to paralyze the target")
  end
  next score
end


# Volt Tackle
PBAI::ScoreHandler.add("RecoilThirdOfDamageDealtParalyzeTarget") do |score, ai, user, target, move|
  if !target.paralyzed? && target.can_paralyze?(user, move)
    score += 10
    PBAI.log("+ 10 for being able to paralyze the target")
  end
  next score
end


# Toxic Thread
PBAI::ScoreHandler.add("PoisonTargetLowerTargetSpeed1") do |score, ai, user, target, move|
  if !target.paralyzed? && target.can_paralyze?(user, move)
    score += 50
    PBAI.log("+ 50 for being able to poison the target")
  end
  if target.battler.pbCanLowerStatStage?(:SPEED, user, move) &&
     target.faster_than?(user)
    score += 30
    PBAI.log("+ 30 for being able to lower target speed")
  end
  next score
end


# Dark Void
PBAI::ScoreHandler.add("SleepTargetIfUserDarkrai") do |score, ai, user, target, move|
  if user.is_species?(:DARKRAI)
    if !target.asleep? && target.can_sleep?(user, move)
      score += 120
      PBAI.log("+ 120 for damaging the target with Nightmare if it is asleep")
    end
  else
    score -= 100
    PBAI.log("- 100 for this move will fail")
  end
  next score
end


# Yawn
PBAI::ScoreHandler.add("SleepTargetNextTurn") do |score, ai, user, target, move|
  if !target.has_non_volatile_status? && target.effects[PBEffects::Yawn] == 0
    score += 60
    PBAI.log("+ 60 for putting the target to sleep")
  end
  next score
end

# Rage
PBAI::ScoreHandler.add("StartRaiseUserAtk1WhenDamaged") do |score, ai, user, target, move|
  dmg = user.get_move_damage(target, move)
  perc = dmg / target.totalhp.to_f
  perc /= 1.5 if user.discourage_making_contact_with?(target)
  score += perc * 150
  next score
end


# Uproar, Thrash, Petal Dance, Outrage, Ice Ball, Rollout
PBAI::ScoreHandler.add("MultiTurnAttackPreventSleeping", "MultiTurnAttackConfuseUserAtEnd", "MultiTurnAttackPowersUpEachTurn") do |score, ai, user, target, move|
  dmg = user.get_move_damage(target, move)
  perc = dmg / target.totalhp.to_f
  perc /= 1.5 if user.discourage_making_contact_with?(target) && move.pbContactMove?(user)
  if perc != 0
    add = perc * 80
    score += add
    PBAI.log("+ #{add} for dealing about #{(perc * 100).round} percent dmg")
  end
  next score
end


# Stealth Rock, Spikes, Toxic Spikes
PBAI::ScoreHandler.add("AddSpikesToFoeSide", "AddToxicSpikesToFoeSide", "AddStealthRocksToFoeSide") do |score, ai, user, target, move|
  if move.function == "AddSpikesToFoeSide" && user.opposing_side.effects[PBEffects::Spikes] >= 3 ||
     move.function == "AddToxicSpikesToFoeSide" && user.opposing_side.effects[PBEffects::ToxicSpikes] >= 2 ||
     move.function == "AddStealthRocksToFoeSide" && user.opposing_side.effects[PBEffects::StealthRock]
    score -= 30
    PBAI.log("- 30 for the opposing side already has max spikes")
  else
    inactive = user.opposing_side.party.size - user.opposing_side.battlers.compact.size
    add = inactive * 30
    add *= (3 - user.opposing_side.effects[PBEffects::Spikes]) / 3.0 if move.function == "AddSpikesToFoeSide"
    add *= 3 / 4.0 if user.opposing_side.effects[PBEffects::ToxicSpikes] == 1 && move.function == "AddToxicSpikesToFoeSide"
    score += add
    PBAI.log("+ #{add} for there are #{inactive} pokemon to be sent out at some point")
    if user.role.id == :HAZARDLEAD
      score += 50
      PBAI.log("+ 50 for being a #{user.role.name}")
    end
  end
  next score
end


# Disable
PBAI::ScoreHandler.add("DisableTargetLastMoveUsed") do |score, ai, user, target, move|
  # Already disabled one of the target's moves
  if target.effects[PBEffects::Disable] > 1
    score -= 30
    PBAI.log("- 30 for the target is already disabled")
  else
    # Get previous damage done by the target
    prevDmg = target.get_damage_by_user(user)
    if prevDmg.size > 0 && prevDmg != 0
      lastDmg = prevDmg[-1]
      # If the last move did more than 50% damage and the target was faster,
      # we can't disable the move in time thus using Disable is pointless.
      if user.is_healing_pointless?(0.5) && target.faster_than?(user)
        score -= 30
        PBAI.log("- 30 for the target move is too strong and the target is faster")
      else
        add = (lastDmg[3] * 150).round
        score += add
        PBAI.log("+ #{add} for we disable a strong move")
      end
    else
      # Target hasn't used a damaging move yet
      score -= 30
      PBAI.log("- 30 for the target hasn't used a damaging move yet.")
    end
  end
  next score
end


# Counter
PBAI::ScoreHandler.add("CounterPhysicalDamage") do |score, ai, user, target, move|
  expect = false
  expect = true if target.is_physical_attacker? && !target.is_healing_necessary?(0.5)
  prevDmg = user.get_damage_by_user(target)
  if prevDmg.size > 0 && prevDmg != 0
    lastDmg = prevDmg[-1]
    lastMove = lastDmg[1]
    expect = true if lastMove.physicalMove?
  end
  # If we can reasonably expect the target to use a physical move
  if expect
    score += 60
    PBAI.log("+ 60 for we can reasonably expect the target to use a physical move")
  end
  next score
end

# Mirror Coat
PBAI::ScoreHandler.add("CounterSpecialDamage") do |score, ai, user, target, move|
  expect = false
  expect = true if target.is_special_attacker? && !target.is_healing_necessary?(0.5)
  prevDmg = user.get_damage_by_user(target)
  if prevDmg.size > 0 && prevDmg != 0
    lastDmg = prevDmg[-1]
    lastMove = lastDmg[1]
    expect = true if lastMove.specialMove?
  end
  # If we can reasonably expect the target to use a special move
  if expect
    score += 60
    PBAI.log("+ 60 for we can reasonably expect the target to use a special move")
  end
  next score
end

# Leech Seed
PBAI::ScoreHandler.add("StartLeechSeedTarget") do |score, ai, user, target, move|
  if !user.underdog?(target) && !target.has_type?(:GRASS) && target.effects[PBEffects::LeechSeed] == 0
    score += 60
    PBAI.log("+ 60 for sapping hp from the target")
    score += 30 if [:PHYSICALWALL,:SPECIALWALL,:PIVOT].include?(user.role.id)
    PBAI.log("+ 30 for being a #{user.role.name}") if [:PHYSICALWALL,:SPECIALWALL,:PIVOT].include?(user.role.id)
  end
  next score
end


# Leech Life, Parabolic Charge, Drain Punch, Giga Drain, Horn Leech, Mega Drain, Absorb
PBAI::ScoreHandler.add("HealUserByHalfOfDamageDone") do |score, ai, user, target, move|
  dmg = user.get_move_damage(target, move)
  add = dmg / 2
  score += add
  PBAI.log("+ #{add} for hp gained")
  next score
end


# Dream Eater
PBAI::ScoreHandler.add("HealUserByHalfOfDamageDoneIfTargetAsleep") do |score, ai, user, target, move|
  if target.asleep?
    dmg = user.get_move_damage(target, move)
    add = dmg / 2
    score += add
    PBAI.log("+ #{add} for hp gained")
  else
    score -= 30
    PBAI.log("- 30 for the move will fail")
  end
  next score
end


# Heal Pulse
PBAI::ScoreHandler.add("HealTargetHalfOfTotalHP") do |score, ai, user, target, move|
  # If the target is an ally
  ally = false
  target.battler.eachAlly do |battler|
    ally = true if battler == user.battler
  end
  if ally# && !target.will_already_be_healed?
    factor = 1 - target.hp / target.totalhp.to_f
    # At full hp, factor is 0 (thus not encouraging this move)
    # At half hp, factor is 0.5 (thus slightly encouraging this move)
    # At 1 hp, factor is about 1.0 (thus encouraging this move)
    if target.will_already_be_healed?
      score -= 30
      PBAI.log("- 30 for the target will already be healed by something")
    elsif factor != 0
      if target.is_healing_pointless?(0.5)
        score -= 10
        PBAI.log("- 10 for the target will take more damage than we can heal if the opponent repeats their move")
      elsif target.is_healing_necessary?(0.5)
        add = (factor * 250).round
        score += add
        PBAI.log("+ #{add} for the target will likely die without healing")
      else
        add = (factor * 125).round
        score += add
        PBAI.log("+ #{add} for the target has lost some hp")
      end
    else
      score -= 30
      PBAI.log("- 30 for the target is at full hp")
    end
  else
    score -= 30
    PBAI.log("- 30 for the target is not an ally")
  end
  next score
end


# Whirlwind, Roar, Circle Throw, Dragon Tail, U-Turn, Volt Switch
PBAI::ScoreHandler.add("SwitchOutTargetStatusMove", "SwitchOutTargetDamagingMove", "SwitchOutUserDamagingMove") do |score, ai, user, target, move|
  if user.bad_against?(target) && user.level >= target.level &&
     !target.has_ability?(:SUCTIONCUPS) && !target.effects[PBEffects::Ingrain] && move.function != "SwitchOutUserDamagingMove"
    score += 100
    PBAI.log("+ 100 for forcing our target to switch and we're bad against our target")
  elsif move.function == "SwitchOutUserDamagingMove"
    if user.role.id == :PIVOT
      score += 40
      PBAI.log("+ 40 for being a #{user.role.name}")
    end
    if user.trapped? && user.can_switch?
      score += 100
      PBAI.log("+ 100 for escaping a trap")
    end
    if target.faster_than?(user) && !user.bad_against?(target)
      score += 20
      PBAI.log("+ 20 for making a more favorable matchup")
    end
    if user.bad_against?(target) && target.faster_than?(user)
      score += 40
      PBAI.log("+ 40 for gaining switch initiative against a bad matchup")
    end
    if user.bad_against?(target) && user.faster_than?(target)
      score += 40
      PBAI.log("+ 40 for switching against a bad matchup")
    end
    boosts = 0
    GameData::Stat.each_battle { |s| boosts += user.stages[s] if user.stages[s] != nil}
    boosts *= -10
    score += boosts
    if boosts > 0
      PBAI.log("+ #{boosts} for switching to reset lowered stats")
    elsif boosts < 0
      PBAI.log("#{boosts} for not wasting boosted stats")
    end
  end
  next score
end


# Anchor Shot, Block, Mean Look, Spider Web, Spirit Shackle, Thousand Waves
PBAI::ScoreHandler.add("TrapTargetInBattle") do |score, ai, user, target, move|
  if target.bad_against?(user) && !target.has_type?(:GHOST)
    score += 100
    PBAI.log("+ 100 for locking our target in battle with us and they're bad against us")
  end
  next score
end

# Recover, Slack Off, Soft-Boiled, Heal Order, Milk Drink, Roost, Wish
PBAI::ScoreHandler.add("HealUserHalfOfTotalHP", "HealUserHalfOfTotalHPLoseFlyingTypeThisTurn", "HealUserPositionNextTurn") do |score, ai, user, target, move|
  factor = 1 - user.hp / user.totalhp.to_f
  # At full hp, factor is 0 (thus not encouraging this move)
  # At half hp, factor is 0.5 (thus slightly encouraging this move)
  if factor != 0
    if user.is_healing_pointless?(0.67)
      score -= 10
      PBAI.log("- 10 for we will take more damage than we can heal if the target repeats their move")
    elsif user.is_healing_necessary?(0.67)
      add = (factor * 250).round
      score += add
      PBAI.log("+ #{add} for we will likely die without healing")
    else
      add = (factor * 125).round
      score += add
      PBAI.log("+ #{add} for we have lost some hp")
    end
  else
    score -= 30
    PBAI.log("- 30 for we are at full hp")
  end
  score += 40 if user.role.id == :CLERIC && move.function == "HealUserPositionNextTurn"
  PBAI.log("+ 40 for being #{user.role.name}") if user.role.id == :CLERIC && move.function == "HealUserPositionNextTurn"
  next score
end


# Moonlight, Morning Sun, Synthesis
PBAI::ScoreHandler.add("HealUserDependingOnWeather") do |score, ai, user, target, move|
  heal_factor = 0.5
  case ai.battle.pbWeather
  when :Sun, :HarshSun
    heal_factor = 2.0 / 3.0
  when :None, :StrongWinds
    heal_factor = 0.5
  else
    heal_factor = 0.25
  end
  effi_factor = 1.0
  effi_factor = 0.5 if heal_factor == 0.25
  factor = 1 - user.hp / user.totalhp.to_f
  # At full hp, factor is 0 (thus not encouraging this move)
  # At half hp, factor is 0.5 (thus slightly encouraging this move)
  # At 1 hp, factor is about 1.0 (thus encouraging this move)
  if factor != 0
    if user.is_healing_pointless?(heal_factor)
      score -= 10
      PBAI.log("- 10 for we will take more damage than we can heal if the target repeats their move")
    elsif user.is_healing_necessary?(heal_factor)
      add = (factor * 250 * effi_factor).round
      score += add
      PBAI.log("+ #{add} for we will likely die without healing")
    else
      add = (factor * 125 * effi_factor).round
      score += add
      PBAI.log("+ #{add} for we have lost some hp")
    end
  else
    score -= 30
    PBAI.log("- 30 for we are at full hp")
  end
  next score
end

# Reflect
PBAI::ScoreHandler.add("StartWeakenPhysicalDamageAgainstUserSide") do |score, ai, user, target, move|
  if user.side.effects[PBEffects::Reflect] > 0
    score -= 30
    PBAI.log("- 30 for reflect is already active")
  else
    enemies = target.side.battlers.select { |proj| !proj.fainted? }.size
    physenemies = target.side.battlers.select { |proj| proj.is_physical_attacker? }.size
    add = enemies * 20 + physenemies * 30
    score += add
    PBAI.log("+ #{add} based on enemy and physical enemy count")
    if user.role.id == :SCREENS
      score += 40
      PBAI.log("+ 40 for being the #{user.role.name} role")
    end
  end
  next score
end


# Light Screen
PBAI::ScoreHandler.add("StartWeakenSpecialDamageAgainstUserSide") do |score, ai, user, target, move|
  if user.side.effects[PBEffects::LightScreen] > 0
    score -= 30
    PBAI.log("- 30 for light screen is already active")
  else
    enemies = target.side.battlers.select { |proj| !proj.fainted? }.size
    specenemies = target.side.battlers.select { |proj| proj.is_special_attacker? }.size
    add = enemies * 20 + specenemies * 30
    score += add
    PBAI.log("+ #{add} based on enemy and special enemy count")
    if user.role.id == :SCREENS
      score += 40
      PBAI.log("+ 40 for being the #{user.role.name} role")
    end
  end
  next score
end

# Aurora Veil
PBAI::ScoreHandler.add("StartWeakenDamageAgainstUserSideIfHail") do |score, ai, user, target, move|
  if user.side.effects[PBEffects::AuroraVeil] > 0
    score -= 30
    PBAI.log("- 30 for Aurora Veil is already active")
  elsif user.effectiveWeather != :Hail
    score -= 30
    PBAI.log("- 30 for Aurora Veil will fail without Hail active")
  else
    enemies = target.side.battlers.select { |proj| !proj.fainted? }.size
    add = enemies * 30
    score += add
    PBAI.log("+ #{add} based on enemy count")
    if user.role.id == :SCREENS
      score += 40
      PBAI.log("+ 40 for being the #{user.role.name} role")
    end
  end
  next score
end

#Taunt
PBAI::ScoreHandler.add("DisableTargetStatusMoves") do |score, ai, user, target, move|
  if target.effects[PBEffects::Taunt]>0
    score -= 30
    PBAI.log("- 30 for the target is already Taunted")
  else
    weight = 0
    target.moves.each do |proj|
      weight += 25 if proj.statusMove?
    end
    score += weight
    PBAI.log("+ #{weight} to Taunt potential stall or setup")
    if user.role.id == :STALLBREAKER && weight > 50
      score += 30
      PBAI.log("+ 30 for being a #{user.role.name}")
    end
  end
  next score
end


# Bide
PBAI::ScoreHandler.add("MultiTurnAttackBideThenReturnDoubleDamage") do |score, ai, user, target, move|
  # If we've been hit at least once, use Bide if we could take two hits of the last attack and survive
  prevDmg = target.get_damage_by_user(user)
  if prevDmg.size > 0 && prevDmg != 0
    lastDmg = prevDmg[-1]
    predDmg = lastDmg[2] * 2
    # We would live if we took two hits of the last move
    if user.hp - predDmg > 0
      score += 120
      PBAI.log("+ 120 for we can survive two subsequent attacks")
    else
      score -= 10
      PBAI.log("- 10 for we would not survive two subsequent attacks")
    end
  else
    score -= 10
    PBAI.log("- 10 for we don't know whether we'd survive two subsequent attacks")
  end
  next score
end

# Swords Dance
PBAI::ScoreHandler.add("RaiseUserAttack2") do |score, ai, user, target, move|
  if user.is_physical_attacker?
    if user.statStageAtMax?(:ATTACK)
      score -= 30
      PBAI.log("- 30 for battler being max Attack")
    else
      count = 0
      user.moves.each do |m|
        count += 1 if user.get_move_damage(target, m) >= target.hp && m.physicalMove?
      end
      t_count = 0
      if target.used_moves != nil
        target.used_moves.each do |tmove|
          if user.faster_than?(target)
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
          else
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
          end
        end
      end
      # As long as the target's stat stages are more advantageous than ours (i.e. net < 0), Haze is a good choice
      PBAI.log("Currently have #{count} moves that can kill")
      PBAI.log("Opponent has #{t_count} moves that can kill")
      if count == 0 && t_count == 0
        add = user.turnCount == 0 ? 60 : 40
        score += add
        PBAI.log("+ #{add} to boost to guarantee the kill")
        if [:SETUPSWEEPER,:PHYSICALBREAKER,:WINCON].include?(user.role.id)
          score += 40
          PBAI.log("+ 40 for being a #{user.role.name}")
        end
      end
    end
  end
  next score
end

# Hone Claws
PBAI::ScoreHandler.add("RaiseUserAtkAcc1") do |score, ai, user, target, move|
  if user.is_physical_attacker?
    if user.statStageAtMax?(:ATTACK)
      score -= 30
      PBAI.log("- 30 for battler being max Attack")
    else
      count = 0
      user.moves.each do |m|
        count += 1 if user.get_move_damage(target, m) >= target.hp && m.physicalMove?
      end
      t_count = 0
      if target.used_moves != nil
        target.used_moves.each do |tmove|
          if user.faster_than?(target)
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
          else
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
          end
        end
      end
      # As long as the target's stat stages are more advantageous than ours (i.e. net < 0), Haze is a good choice
      PBAI.log("Currently have #{count} moves that can kill")
      PBAI.log("Opponent has #{t_count} moves that can kill")
      if count == 0 && t_count == 0
        add = user.turnCount == 0 ? 60 : 40
        score += add
        PBAI.log("+ #{add} to boost to guarantee the kill")
        if [:SETUPSWEEPER,:PHYSICALBREAKER,:WINCON].include?(user.role.id)
          score += 40
          PBAI.log("+ 40 for being a #{user.role.name}")
        end
      end
    end
  end
  next score
end

# String Shot
PBAI::ScoreHandler.add("LowerTargetSpeed2") do |score, ai, user, target, move|
  if target.statStageAtMin?(:SPEED)
    score = 0
    PBAI.log("*0 for not being able to lower speed")
  else
    spe = target.stages[:SPEED]
    stat = (20 * spe) + (target.effective_speed)
    score += stat
    PBAI.log("+ #{stat} for Speed changes and effective Speed")
    if user.role.id == :SPEEDCONTROL
      score += 50
      PBAI.log("+ 50 for being a #{user.role.name}")
    end
  end
  t_count = 0
  if target.used_moves != nil
    target.used_moves.each do |tmove|
      if user.faster_than?(target)
        t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
      else
        t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
      end
    end
  end
  if !user.can_switch? && t_count > 0
    score = 0
    PBAI.log("*0 because lowering Speed is pointless when we will die")
  end
  next score
end

# Bulk Up
PBAI::ScoreHandler.add("RaiseUserAtkDef1") do |score, ai, user, target, move|
  if user.is_physical_attacker?
    if user.statStageAtMax?(:ATTACK) || user.statStageAtMax?(:DEFENSE)
      score -= 30
      PBAI.log("- 30 for battler being max on Attack or Defense")
    else
      count = 0
      user.moves.each do |m|
        count += 1 if user.get_move_damage(target, m) >= target.hp && m.physicalMove?
      end
      t_count = 0
      if target.used_moves != nil
        target.used_moves.each do |tmove|
          if user.faster_than?(target)
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
          else
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
          end
        end
      end
      # As long as the target's stat stages are more advantageous than ours (i.e. net < 0), Haze is a good choice
      PBAI.log("Currently have #{count} moves that can kill")
      PBAI.log("Opponent has #{t_count} moves that can kill")
      if count == 0 && t_count == 0
        add = user.turnCount == 0 ? 60 : 40
        score += add
        PBAI.log("+ #{add} to boost to guarantee the kill")
        if [:SETUPSWEEPER,:PHYSICALBREAKER,:WINCON].include?(user.role.id)
          score += 40
          PBAI.log("+ 40 for being a #{user.role.name}")
        end
      end
    end
  end
  next score
end

# Nasty Plot
PBAI::ScoreHandler.add("RaiseUserSpAtk2") do |score, ai, user, target, move|
  if user.is_special_attacker?
    if user.statStageAtMax?(:SPECIAL_ATTACK)
      score -= 30
      PBAI.log("- 30 for battler being max Special Attack")
    else
      count = 0
      user.moves.each do |m|
        count += 1 if user.get_move_damage(target, m) >= target.hp && m.specialMove?
      end
      t_count = 0
      if target.used_moves != nil
        target.used_moves.each do |tmove|
          if user.faster_than?(target)
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
          else
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
          end
        end
      end
      # As long as the target's stat stages are more advantageous than ours (i.e. net < 0), Haze is a good choice
      PBAI.log("Currently have #{count} moves that can kill")
      PBAI.log("Opponent has #{t_count} moves that can kill")
      if count == 0 && t_count == 0
        add = user.turnCount == 0 ? 60 : 40
        score += add
        PBAI.log("+ #{add} to boost to guarantee the kill")
        if [:SETUPSWEEPER,:SPECIALBREAKER,:WINCON].include?(user.role.id)
          score += 40
          PBAI.log("+ 40 for being a #{user.role.name}")
        end
      end
    end
  end
  next score
end

# Calm Mind
PBAI::ScoreHandler.add("RaiseUserSpAtkSpDef1") do |score, ai, user, target, move|
  if user.is_special_attacker?
    if user.statStageAtMax?(:SPECIAL_ATTACK) || user.statStageAtMax?(:SPECIAL_DEFENSE)
      score -= 30
      PBAI.log("- 30 for battler being max Special Attack or Special Defense")
    else
      count = 0
      user.moves.each do |m|
        count += 1 if user.get_move_damage(target, m) >= target.hp && m.specialMove?
      end
      t_count = 0
      if target.used_moves != nil
        target.used_moves.each do |tmove|
          if user.faster_than?(target)
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp
          else
            t_count += 1 if target.get_move_damage(user, tmove) >= target.hp/2
          end
        end
      end
      # As long as the target's stat stages are more advantageous than ours (i.e. net < 0), Haze is a good choice
      PBAI.log("Currently have #{count} moves that can kill")
      PBAI.log("Opponent has #{t_count} moves that can kill")
      if count == 0 && t_count == 0
        add = user.turnCount == 0 ? 60 : 40
        score += add
        PBAI.log("+ #{add} to boost to guarantee the kill")
        if [:SETUPSWEEPER,:SPECIALBREAKER,:WINCON].include?(user.role.id)
          score += 40
          PBAI.log("+ 40 for being a #{user.role.name}")
        end
      end
    end
  end
  next score
end

PBAI::ScoreHandler.add("HigherPriorityInGrassyTerrain") do |score, ai, user, target, move|
  if ai.battle.field.terrain == :Grassy
    pri = 0
    for i in user.used_moves
      pri += 1 if i.priority > 0 && i.damagingMove?
    end
    if target.faster_than?(user)
      score += 50
      PBAI.log("+ 50 for being a priority move to outspeed opponent")
      if user.get_move_damage(target, move) >= target.hp
        score += 20
        PBAI.log("+ 20 for being able to KO with priority")
      end
    end
    if pri > 0
      score += 50
      PBAI.log("+ 50 for being a priority move to counter opponent's priority")
      if user.faster_than?(target)
        score += 20
        PBAI.log("+ 20 for outprioritizing opponent")
      end
    end
    if user.underdog?(target)
      score += 50
      PBAI.log("+ 50 for being a priority move and being and underdog")
    end
  end
  score += 20
  field = "Grassy Terrain boost"
  PBAI.log("+ 20 for #{field}")
  next score
end

PBAI::ScoreHandler.add("RemoveUserBindingAndEntryHazards","LowerTargetEvasion1RemoveSideEffects") do |score, ai, user, target, move|
  rocks = 0
  webs = 0
  spikes = !user.effects[PBEffects::Spikes] ? 0 : user.effects[PBEffects::Spikes]
  tspikes = !user.effects[PBEffects::ToxicSpikes] ? 0 : user.effects[PBEffects::ToxicSpikes]
  rocks = 1 if user.effects[PBEffects::StealthRock]
  webs = 1 if user.effects[PBEffects::StickyWeb]
  haz = 0
  hazards = rocks + spikes + tspikes + webs
  if hazards > 0
    haz += (100 * spikes) + (150 * tspikes) + (200 * rocks) + (150 * webs)
    score += haz
    PBAI.log("+ #{haz} for removing hazards")
    if user.role == :HAZARDREMOVAL
      score += 30
      PBAI.log("+ 30 for being #{user.role.name}")
    end
  else
    score = 0
    PBAI.log("* 0 for not having any hazards to remove")
  end
  next score
end

#Rage Powder, Follow Me
PBAI::ScoreHandler.add("RedirectAllMovesToUser") do |score, ai, user, target, move|
  if ai.battle.pbSideSize(0) == 2
    ally = false
    b = nil
    enemy = []
    user.battler.eachAlly do |battler|
      ally = true if battler != user.battler
    end
    if ally
      ai.battle.eachOtherSideBattler(user.index) do |opp|
        enemy.push(opp)
      end
      mon = user.side.battlers.find {|proj| proj && proj != self && !proj.fainted?}
      if user.role.id == :REDIRECTION && (mon.bad_against?(enemy[0]) || mon.bad_against?(enemy[1]))
        score += 200
        PBAI.log("+ 200 for redirecting an attack away from partner")
      end
    end
  else
    score = 0
    PBAI.log("* 0 because move will fail")
  end
  next score
end

#Skill Swap Specific for Fiery
PBAI::ScoreHandler.add("UserTargetSwapAbilitiesSpecial") do |score, ai, user, target, move|
  if user.turnCount == 0 && user.role.id == :SKILLSWAPALLY
    score += 1000
    PBAI.log("+ 1000 for being a #{user.role.name} and it being first turn")
  else
    score = 0
    PBAI.log("*0 for it being past turn 1")
  end
  next score
end

#Level Trainer
PBAI::ScoreHandler.add("UserFaintsLowerTargetAtkSpAtk2") do |score, ai, user, target, move|
  if user.moves.length == 1
    score += 10000
    PBAI.log("+ 10000 for being a level trainer mon")
  end
  next score
end

#Trick Room
PBAI::ScoreHandler.add("StartSlowerBattlersActFirst") do |score, ai, user, target, move|
  if ai.battle.field.effects[PBEffects::TrickRoom] == 0 && target.faster_than?(user)
    score += 100
    PBAI.log("+ 100 for setting Trick Room to outspeed target")
    if user.role.id == :TRICKROOMSETTER
      score += 100
      PBAI.log("+ 100 for being a #{user.role.name}")
    end
  else
    score -= 1000
    PBAI.log("- 1000 to not undo Trick Room") if ai.battle.field.effects[PBEffects::TrickRoom] != 0
  end
  next score
end