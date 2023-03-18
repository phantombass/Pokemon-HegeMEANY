module Battle::AbilityEffects
  Instinct                      = AbilityHandlerHash.new
  def self.triggerInstinct(ability, battler, battle, end_of_battle)
    Instinct.trigger(ability, battler, battle, end_of_battle)
  end
end

class Battle::Battler
  def immune_by_ability?(type,ability)
    if type == :ROCK && ability == :SCALER
      return true
    end
    if type == :FIRE && [:FLASHFIRE,:WELLBAKEDBODY].include?(ability)
      return true
    end
    if type == :GRASS && ability == :SAPSIPPER
      return true
    end
    if type == :WATER && [:STORMDRAIN,:WATERABSORB,:DRYSKIN].include?(ability)
      return true
    end
    if type == :GROUND && [:LEVITATE,:EARTHEATER].include?(ability)
      return true
    end
    if type == :ELECTRIC && [:VOLTABSORB,:MOTORDRIVE,:LIGHTNINGROD].include?(ability)
      return true
    end
    if type == :ICE && ability == :DEFROST
      return true
    end
    return false
  end
  def pbInitEffects(batonPass)
    if batonPass
      # These effects are passed on if Baton Pass is used, but they need to be
      # reapplied
      @effects[PBEffects::LaserFocus] = (@effects[PBEffects::LaserFocus] > 0) ? 2 : 0
      @effects[PBEffects::LockOn]     = (@effects[PBEffects::LockOn] > 0) ? 2 : 0
      if @effects[PBEffects::PowerTrick]
        @attack, @defense = @defense, @attack
      end
      # These effects are passed on if Baton Pass is used, but they need to be
      # cancelled in certain circumstances anyway
      @effects[PBEffects::Telekinesis] = 0 if isSpecies?(:GENGAR) && mega?
      @effects[PBEffects::GastroAcid]  = false if unstoppableAbility?
    else
      # These effects are passed on if Baton Pass is used
      GameData::Stat.each_battle { |stat| @stages[stat.id] = 0 }
      @effects[PBEffects::AquaRing]          = false
      @effects[PBEffects::Confusion]         = 0
      @effects[PBEffects::Curse]             = false
      @effects[PBEffects::Embargo]           = 0
      @effects[PBEffects::FocusEnergy]       = 0
      @effects[PBEffects::GastroAcid]        = false
      @effects[PBEffects::HealBlock]         = 0
      @effects[PBEffects::Ingrain]           = false
      @effects[PBEffects::LaserFocus]        = 0
      @effects[PBEffects::LeechSeed]         = -1
      @effects[PBEffects::LockOn]            = 0
      @effects[PBEffects::LockOnPos]         = -1
      @effects[PBEffects::MagnetRise]        = 0
      @effects[PBEffects::PerishSong]        = 0
      @effects[PBEffects::PerishSongUser]    = -1
      @effects[PBEffects::PowerTrick]        = false
      @effects[PBEffects::Substitute]        = 0
      @effects[PBEffects::Telekinesis]       = 0
    end
    @fainted               = (@hp == 0)
    @lastAttacker          = []
    @lastFoeAttacker       = []
    @lastHPLost            = 0
    @lastHPLostFromFoe     = 0
    @droppedBelowHalfHP    = false
    @statsDropped          = false
    @tookDamageThisRound   = false
    @tookPhysicalHit       = false
    @statsRaisedThisRound  = false
    @statsLoweredThisRound = false
    @canRestoreIceFace     = false
    @lastMoveUsed          = nil
    @lastMoveUsedType      = nil
    @lastRegularMoveUsed   = nil
    @lastRegularMoveTarget = -1
    @lastRoundMoved        = -1
    @lastMoveFailed        = false
    @lastRoundMoveFailed   = false
    @movesUsed             = []
    @turnCount             = 0
    @effects[PBEffects::Attract]             = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer attracted to self
      b.effects[PBEffects::Attract] = -1 if b.effects[PBEffects::Attract] == @index
    end
    @effects[PBEffects::BanefulBunker]       = false
    @effects[PBEffects::BeakBlast]           = false
    @effects[PBEffects::Bide]                = 0
    @effects[PBEffects::BideDamage]          = 0
    @effects[PBEffects::BideTarget]          = -1
    @effects[PBEffects::BurnUp]              = false
    @effects[PBEffects::Charge]              = 0
    @effects[PBEffects::ChoiceBand]          = nil
    @effects[PBEffects::Counter]             = -1
    @effects[PBEffects::CounterTarget]       = -1
    @effects[PBEffects::Dancer]              = false
    @effects[PBEffects::DefenseCurl]         = false
    @effects[PBEffects::DestinyBond]         = false
    @effects[PBEffects::DestinyBondPrevious] = false
    @effects[PBEffects::DestinyBondTarget]   = -1
    @effects[PBEffects::Disable]             = 0
    @effects[PBEffects::DisableMove]         = nil
    @effects[PBEffects::Electrify]           = false
    @effects[PBEffects::Encore]              = 0
    @effects[PBEffects::EncoreMove]          = nil
    @effects[PBEffects::Endure]              = false
    @effects[PBEffects::FirstPledge]         = nil
    @effects[PBEffects::FlashFire]           = false
    @effects[PBEffects::Flinch]              = false
    @effects[PBEffects::FocusPunch]          = false
    @effects[PBEffects::FollowMe]            = 0
    @effects[PBEffects::Foresight]           = false
    @effects[PBEffects::FuryCutter]          = 0
    @effects[PBEffects::GemConsumed]         = nil
    @effects[PBEffects::Grudge]              = false
    @effects[PBEffects::HelpingHand]         = false
    @effects[PBEffects::HyperBeam]           = 0
    @effects[PBEffects::Illusion]            = nil
    if hasActiveAbility?(:ILLUSION)
      idxLastParty = @battle.pbLastInTeam(@index)
      if idxLastParty >= 0 && idxLastParty != @pokemonIndex
        @effects[PBEffects::Illusion]        = @battle.pbParty(@index)[idxLastParty]
      end
    end
    @effects[PBEffects::Imprison]            = false
    @effects[PBEffects::Instruct]            = false
    @effects[PBEffects::Instructed]          = false
    @effects[PBEffects::JawLock]             = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer blocked by self
      b.effects[PBEffects::JawLock] = -1 if b.effects[PBEffects::JawLock] == @index
    end
    @effects[PBEffects::KingsShield]         = false
    @battle.allBattlers.each do |b|   # Other battlers lose their lock-on against self
      next if b.effects[PBEffects::LockOn] == 0
      next if b.effects[PBEffects::LockOnPos] != @index
      b.effects[PBEffects::LockOn]    = 0
      b.effects[PBEffects::LockOnPos] = -1
    end
    @effects[PBEffects::MagicBounce]         = false
    @effects[PBEffects::MagicCoat]           = false
    @effects[PBEffects::MeanLook]            = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer blocked by self
      b.effects[PBEffects::MeanLook] = -1 if b.effects[PBEffects::MeanLook] == @index
    end
    @effects[PBEffects::MeFirst]             = false
    @effects[PBEffects::Metronome]           = 0
    @effects[PBEffects::MicleBerry]          = false
    @effects[PBEffects::Minimize]            = false
    @effects[PBEffects::MiracleEye]          = false
    @effects[PBEffects::MirrorCoat]          = -1
    @effects[PBEffects::MirrorCoatTarget]    = -1
    @effects[PBEffects::MoveNext]            = false
    @effects[PBEffects::MudSport]            = false
    @effects[PBEffects::Nightmare]           = false
    @effects[PBEffects::NoRetreat]           = false
    @effects[PBEffects::Obstruct]            = false
    @effects[PBEffects::Octolock]            = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer locked by self
      b.effects[PBEffects::Octolock] = -1 if b.effects[PBEffects::Octolock] == @index
    end
    @effects[PBEffects::Outrage]             = 0
    @effects[PBEffects::ParentalBond]        = 0
    @effects[PBEffects::PickupItem]          = nil
    @effects[PBEffects::PickupUse]           = 0
    @effects[PBEffects::Pinch]               = false
    @effects[PBEffects::Powder]              = false
    @effects[PBEffects::Prankster]           = false
    @effects[PBEffects::PriorityAbility]     = false
    @effects[PBEffects::PriorityItem]        = false
    @effects[PBEffects::Protect]             = false
    @effects[PBEffects::ProtectRate]         = 1
    @effects[PBEffects::Quash]               = 0
    @effects[PBEffects::Rage]                = false
    @effects[PBEffects::RagePowder]          = false
    @effects[PBEffects::Rollout]             = 0
    @effects[PBEffects::Roost]               = false
    @effects[PBEffects::Singed]              = 0
    @effects[PBEffects::SkyDrop]             = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer Sky Dropped by self
      b.effects[PBEffects::SkyDrop] = -1 if b.effects[PBEffects::SkyDrop] == @index
    end
    @effects[PBEffects::SlowStart]           = 0
    @effects[PBEffects::SmackDown]           = false
    @effects[PBEffects::Snatch]              = 0
    @effects[PBEffects::SpikyShield]         = false
    @effects[PBEffects::Spotlight]           = 0
    @effects[PBEffects::Stockpile]           = 0
    @effects[PBEffects::StockpileDef]        = 0
    @effects[PBEffects::StockpileSpDef]      = 0
    @effects[PBEffects::TarShot]             = false
    @effects[PBEffects::Taunt]               = 0
    @effects[PBEffects::ThroatChop]          = 0
    @effects[PBEffects::Torment]             = false
    @effects[PBEffects::Toxic]               = 0
    @effects[PBEffects::Transform]           = false
    @effects[PBEffects::TransformSpecies]    = nil
    @effects[PBEffects::Trapping]            = 0
    @effects[PBEffects::TrappingMove]        = nil
    @effects[PBEffects::TrappingUser]        = -1
    @battle.allBattlers.each do |b|   # Other battlers no longer trapped by self
      next if b.effects[PBEffects::TrappingUser] != @index
      b.effects[PBEffects::Trapping]     = 0
      b.effects[PBEffects::TrappingUser] = -1
    end
    @effects[PBEffects::Truant]              = false
    @effects[PBEffects::TwoTurnAttack]       = nil
    @effects[PBEffects::Type3]               = nil
    @effects[PBEffects::Unburden]            = false
    @effects[PBEffects::Uproar]              = 0
    @effects[PBEffects::WaterSport]          = false
    @effects[PBEffects::WeightChange]        = 0
    @effects[PBEffects::Yawn]                = 0
    @effects[PBEffects::CaennerbongDance]    = false
  end
  def pbEndTurn(_choice)
    @lastRoundMoved = @battle.turnCount   # Done something this round
    if !@effects[PBEffects::ChoiceBand] &&
       (hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF]) ||
       hasActiveAbility?(:GORILLATACTICS) || hasActiveAbility?(:FORESTSSECRETS))
      if @lastMoveUsed && pbHasMove?(@lastMoveUsed)
        @effects[PBEffects::ChoiceBand] = @lastMoveUsed
      elsif @lastRegularMoveUsed && pbHasMove?(@lastRegularMoveUsed)
        @effects[PBEffects::ChoiceBand] = @lastRegularMoveUsed
      end
    end
    @effects[PBEffects::BeakBlast]   = false
    @effects[PBEffects::Charge]      = 0 if @effects[PBEffects::Charge] == 1
    @effects[PBEffects::GemConsumed] = nil
    @effects[PBEffects::ShellTrap]   = false
    @battle.allBattlers.each { |b| b.pbContinualAbilityChecks }   # Trace, end primordial weathers
  end
  def pbCanChooseMove?(move, commandPhase, showMessages = true, specialUsage = false)
    # Disable
    if @effects[PBEffects::DisableMove] == move.id && !specialUsage
      if showMessages
        msg = _INTL("{1}'s {2} is disabled!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Heal Block
    if @effects[PBEffects::HealBlock] > 0 && move.healingMove?
      if showMessages
        msg = _INTL("{1} can't use {2} because of Heal Block!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Gravity
    if @battle.field.effects[PBEffects::Gravity] > 0 && move.unusableInGravity?
      if showMessages
        msg = _INTL("{1} can't use {2} because of gravity!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Throat Chop
    if @effects[PBEffects::ThroatChop] > 0 && move.soundMove?
      if showMessages
        msg = _INTL("{1} can't use {2} because of Throat Chop!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Choice Band/Gorilla Tactics
    @effects[PBEffects::ChoiceBand] = nil if !pbHasMove?(@effects[PBEffects::ChoiceBand])
    if @effects[PBEffects::ChoiceBand] && move.id != @effects[PBEffects::ChoiceBand]
      choiced_move_name = GameData::Move.get(@effects[PBEffects::ChoiceBand]).name
      if hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF])
        if showMessages
          msg = _INTL("The {1} only allows the use of {2}!", itemName, choiced_move_name)
          (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
        end
        return false
      elsif hasActiveAbility?(:GORILLATACTICS) || hasActiveAbility?(:FORESTSSECRETS)
        if showMessages
          msg = _INTL("{1} can only use {2}!", pbThis, choiced_move_name)
          (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
        end
        return false
      end
    end
    # Taunt
    if @effects[PBEffects::Taunt] > 0 && move.statusMove?
      if showMessages
        msg = _INTL("{1} can't use {2} after the taunt!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Torment
    if @effects[PBEffects::Torment] && !@effects[PBEffects::Instructed] &&
       @lastMoveUsed && move.id == @lastMoveUsed && move.id != @battle.struggle.id
      if showMessages
        msg = _INTL("{1} can't use the same move twice in a row due to the torment!", pbThis)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Imprison
    if @battle.allOtherSideBattlers(@index).any? { |b| b.effects[PBEffects::Imprison] && b.pbHasMove?(move.id) }
      if showMessages
        msg = _INTL("{1} can't use its sealed {2}!", pbThis, move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Assault Vest (prevents choosing status moves but doesn't prevent
    # executing them)
    if hasActiveItem?(:ASSAULTVEST) && move.statusMove? && move.id != :MEFIRST && commandPhase
      if showMessages
        msg = _INTL("The effects of the {1} prevent status moves from being used!", itemName)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Belch
    return false if !move.pbCanChooseMove?(self, commandPhase, showMessages)
    return true
  end
  def pbTypes(withType3 = false)
    ret = @types.uniq
    # Burn Up erases the Fire-type.
    ret.delete(:FIRE) if @effects[PBEffects::BurnUp]
    # Roost erases the Flying-type. If there are no types left, adds the Normal-
    # type.
    if @effects[PBEffects::Roost]
      ret.delete(:FLYING)
      ret.push(:NORMAL) if ret.length == 0
    end
    if @effects[PBEffects::Singed] == 1
      ret.delete(:FLYING)
    end
    # Add the third type specially.
    if withType3 && @effects[PBEffects::Type3] && !ret.include?(@effects[PBEffects::Type3])
      ret.push(@effects[PBEffects::Type3])
    end
    return ret
  end
  def pbCanSleepYawn?
    return false if self.status != :NONE
    if affectedByTerrain? && [:Electric, :Misty].include?(@battle.field.terrain)
      return false
    end
    if !hasActiveAbility?(:SOUNDPROOF) && @battle.allBattlers.any? { |b| b.effects[PBEffects::Uproar] > 0 }
      return false
    end
    if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability, self, :SLEEP)
      return false
    end
    # NOTE: Bulbapedia claims that Flower Veil shouldn't prevent sleep due to
    #       drowsiness, but I disagree because that makes no sense. Also, the
    #       comparable Sweet Veil does prevent sleep due to drowsiness.
    if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability, self, :SLEEP)
      return false
    end
    @battle.allBattlers.each do |pkmn|
      if pkmn.hasActiveItem?(:CACOPHONYORB) && !pkmn.hasActiveAbility?(:SOUNDPROOF)
        @battle.pbDisplay(_INTL("But the Cacophony kept it awake!"))
        return false
      end
    end
    allAllies.each do |b|
      next if !b.abilityActive?
      next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability, self, :SLEEP)
      return false
    end
    # NOTE: Bulbapedia claims that Safeguard shouldn't prevent sleep due to
    #       drowsiness. I disagree with this too. Compare with the other sided
    #       effects Misty/Electric Terrain, which do prevent it.
    return false if pbOwnSide.effects[PBEffects::Safeguard] > 0
    return true
  end
  def pbCanInflictStatus?(newStatus,user,showMessages,move=nil,ignoreStatus=false)
    return false if fainted?
    if @battle.field.field_effects == :Ruins && self.pbHasType?(:DRAGON)
      @battle.pbDisplay(_INTL("{1} is protected by the power in the ancient ruins!",pbThis(true))) if showMessages
      return false
    end
    selfInflicted = (user && user.index==@index)
    # Already have that status problem
    if self.status==newStatus && !ignoreStatus
      if showMessages
        msg = ""
        case self.status
        when :SLEEP     then msg = _INTL("{1} is already asleep!", pbThis)
        when :POISON    then msg = _INTL("{1} is already poisoned!", pbThis)
        when :BURN      then msg = _INTL("{1} already has a burn!", pbThis)
        when :PARALYSIS then msg = _INTL("{1} is already paralyzed!", pbThis)
        when :FROZEN    then msg = _INTL("{1} is already frostbitten!", pbThis)
        end
        @battle.pbDisplay(msg)
      end
      return false
    end
    # Trying to replace a status problem with another one
    if self.status != :NONE && !ignoreStatus && !selfInflicted
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Trying to inflict a status problem on a Pokémon behind a substitute
    if @effects[PBEffects::Substitute]>0 && !(move && move.ignoresSubstitute?(user)) &&
       !selfInflicted
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Weather immunity
    if newStatus == :FROZEN && [:Sun, :HarshSun].include?(@battle.pbWeather)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Terrains immunity
    if affectedByTerrain?
      case @battle.field.terrain
      when :Electric
        if newStatus == :SLEEP
          @battle.pbDisplay(_INTL("{1} surrounds itself with electrified terrain!",
             pbThis(true))) if showMessages
          return false
        end
      when :Misty
        @battle.pbDisplay(_INTL("{1} surrounds itself with misty terrain!",pbThis(true))) if showMessages
        return false
      end
    end
    # Uproar immunity
    if newStatus == :SLEEP && !(hasActiveAbility?(:SOUNDPROOF) && !@battle.moldBreaker)
      @battle.eachBattler do |b|
        next if b.effects[PBEffects::Uproar]==0
        @battle.pbDisplay(_INTL("But the uproar kept {1} awake!",pbThis(true))) if showMessages
        return false
      end
    end
    # Cacophony Immunity
    if newStatus == :SLEEP && (hasActiveAbility?(:CACOPHONY) || hasActiveItem?(:CACOPHONYORB))
      @battle.eachBattler do |b|
        next if hasActiveAbility?(:SOUNDPROOF)
        @battle.pbDisplay(_INTL("But the uproar kept {1} awake!",pbThis(true))) if showMessages
        return false
      end
    end
    # Type immunities
    hasImmuneType = false
    case newStatus
    when :SLEEP
      # No type is immune to sleep
    when :POISON
      if !(user && user.hasActiveAbility?(:CORROSION))
        hasImmuneType |= pbHasType?(:POISON)
        hasImmuneType |= pbHasType?(:STEEL)
      end
    when :BURN
      hasImmuneType |= pbHasType?(:FIRE)
    when :PARALYSIS
      hasImmuneType |= pbHasType?(:ELECTRIC) && Settings::MORE_TYPE_EFFECTS
    when :FROZEN
      hasImmuneType |= pbHasType?(:ICE)
    end
    if hasImmuneType
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",pbThis(true))) if showMessages
      return false
    end
    # Ability immunity
    immuneByAbility = false; immAlly = nil
    if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability,self,newStatus)
      immuneByAbility = true
    elsif selfInflicted || !@battle.moldBreaker
      if abilityActive? && Battle::AbilityEffects.triggerStatusImmunity(self.ability,self,newStatus)
        immuneByAbility = true
      else
        eachAlly do |b|
          next if !b.abilityActive?
          next if !Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability,self,newStatus)
          immuneByAbility = true
          immAlly = b
          break
        end
      end
    end
    if immuneByAbility
      if showMessages
        @battle.pbShowAbilitySplash(immAlly || self)
        msg = ""
        if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          case newStatus
          when :SLEEP     then msg = _INTL("{1} stays awake!", pbThis)
          when :POISON    then msg = _INTL("{1} cannot be poisoned!", pbThis)
          when :BURN      then msg = _INTL("{1} cannot be burned!", pbThis)
          when :PARALYSIS then msg = _INTL("{1} cannot be paralyzed!", pbThis)
          when :FROZEN    then msg = _INTL("{1} cannot be frostbitten!", pbThis)
          end
        elsif immAlly
          case newStatus
          when :SLEEP
            msg = _INTL("{1} stays awake because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :POISON
            msg = _INTL("{1} cannot be poisoned because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :BURN
            msg = _INTL("{1} cannot be burned because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :PARALYSIS
            msg = _INTL("{1} cannot be paralyzed because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          when :FROZEN
            msg = _INTL("{1} cannot be frozen solid because of {2}'s {3}!",
               pbThis,immAlly.pbThis(true),immAlly.abilityName)
          end
        else
          case newStatus
          when :SLEEP     then msg = _INTL("{1} stays awake because of its {2}!", pbThis, abilityName)
          when :POISON    then msg = _INTL("{1}'s {2} prevents poisoning!", pbThis, abilityName)
          when :BURN      then msg = _INTL("{1}'s {2} prevents burns!", pbThis, abilityName)
          when :PARALYSIS then msg = _INTL("{1}'s {2} prevents paralysis!", pbThis, abilityName)
          when :FROZEN    then msg = _INTL("{1}'s {2} prevents freezing!", pbThis, abilityName)
          end
        end
        @battle.pbDisplay(msg)
        @battle.pbHideAbilitySplash(immAlly || self)
      end
      return false
    end
    # Safeguard immunity
    if pbOwnSide.effects[PBEffects::Safeguard]>0 && !selfInflicted && move &&
       !(user && user.hasActiveAbility?(:INFILTRATOR))
      @battle.pbDisplay(_INTL("{1}'s team is protected by Safeguard!",pbThis)) if showMessages
      return false
    end
    return true
  end
  def pbInflictStatus(newStatus, newStatusCount = 0, msg = nil, user = nil)
    # Inflict the new status
    self.status      = newStatus
    self.statusCount = newStatusCount
    @effects[PBEffects::Toxic] = 0
    # Show animation
    if newStatus == :POISON && newStatusCount > 0
      @battle.pbCommonAnimation("Toxic", self)
    else
      anim_name = GameData::Status.get(newStatus).animation
      @battle.pbCommonAnimation(anim_name, self) if anim_name
    end
    # Show message
    if msg && !msg.empty?
      @battle.pbDisplay(msg)
    else
      case newStatus
      when :SLEEP
        @battle.pbDisplay(_INTL("{1} fell asleep!", pbThis))
      when :POISON
        if newStatusCount > 0
          @battle.pbDisplay(_INTL("{1} was badly poisoned!", pbThis))
        else
          @battle.pbDisplay(_INTL("{1} was poisoned!", pbThis))
        end
      when :BURN
        @battle.pbDisplay(_INTL("{1} was burned!", pbThis))
      when :PARALYSIS
        @battle.pbDisplay(_INTL("{1} is paralyzed! It may be unable to move!", pbThis))
      when :FROZEN
        @battle.pbDisplay(_INTL("{1} was hurt by frostbite!", pbThis))
      end
    end
    PBDebug.log("[Status change] #{pbThis}'s sleep count is #{newStatusCount}") if newStatus == :SLEEP
    # Form change check
    pbCheckFormOnStatusChange
    # Synchronize
    if abilityActive?
      Battle::AbilityEffects.triggerOnStatusInflicted(self.ability, self, user, newStatus)
    end
    # Status cures
    pbItemStatusCureCheck
    pbAbilityStatusCureCheck
    # Petal Dance/Outrage/Thrash get cancelled immediately by falling asleep
    # NOTE: I don't know why this applies only to Outrage and only to falling
    #       asleep (i.e. it doesn't cancel Rollout/Uproar/other multi-turn
    #       moves, and it doesn't cancel any moves if self becomes frozen/
    #       disabled/anything else). This behaviour was tested in Gen 5.
    if @status == :SLEEP && @effects[PBEffects::Outrage] > 0
      @effects[PBEffects::Outrage] = 0
      @currentMove = nil
    end
  end
  def pbContinueStatus
    if self.status == :POISON && @statusCount > 0
      @battle.pbCommonAnimation("Toxic", self)
    else
      anim_name = GameData::Status.get(self.status).animation
      @battle.pbCommonAnimation(anim_name, self) if anim_name
    end
    yield if block_given?
    case self.status
    when :SLEEP
      @battle.pbDisplay(_INTL("{1} is asleep.", pbThis))
    when :POISON
      @battle.pbDisplay(_INTL("{1} was hurt by poison!", pbThis))
    when :BURN
      @battle.pbDisplay(_INTL("{1} was hurt by its burn!", pbThis))
    when :PARALYSIS
      @battle.pbDisplay(_INTL("{1} is paralyzed! It can't move!", pbThis))
    when :FROZEN
      @battle.pbDisplay(_INTL("{1} was hurt by frostbite!", pbThis))
    end
    PBDebug.log("[Status continues] #{pbThis}'s sleep count is #{@statusCount}") if self.status == :SLEEP
  end
  def pbCureStatus(showMessages = true)
    oldStatus = status
    self.status = :NONE
    if showMessages
      case oldStatus
      when :SLEEP     then @battle.pbDisplay(_INTL("{1} shook off the drowsiness!", pbThis))
      when :POISON    then @battle.pbDisplay(_INTL("{1} was cured of its poisoning.", pbThis))
      when :BURN      then @battle.pbDisplay(_INTL("{1}'s burn was healed.", pbThis))
      when :PARALYSIS then @battle.pbDisplay(_INTL("{1} was cured of paralysis.", pbThis))
      when :FROZEN    then @battle.pbDisplay(_INTL("{1} was cured of its frostbite!", pbThis))
      end
    end
    PBDebug.log("[Status change] #{pbThis}'s status was cured") if !showMessages
  end
  def pbTryUseMove(choice,move,specialUsage,skipAccuracyCheck)
    # Check whether it's possible for self to use the given move
    # NOTE: Encore has already changed the move being used, no need to have a
    #       check for it here.
    if !pbCanChooseMove?(move,false,true,specialUsage)
      @lastMoveFailed = true
      return false
    end
    # Check whether it's possible for self to do anything at all
    if @effects[PBEffects::SkyDrop]>=0   # Intentionally no message here
      PBDebug.log("[Move failed] #{pbThis} can't use #{move.name} because of being Sky Dropped")
      return false
    end
    if @effects[PBEffects::HyperBeam]>0   # Intentionally before Truant
      @battle.pbDisplay(_INTL("{1} must recharge!",pbThis))
      return false
    end
    if choice[1]==-2   # Battle Palace
      @battle.pbDisplay(_INTL("{1} appears incapable of using its power!",pbThis))
      return false
    end
    # Skip checking all applied effects that could make self fail doing something
    return true if skipAccuracyCheck
    # Check status problems and continue their effects/cure them
    case @status
    when :SLEEP
      self.statusCount -= 1
      if @statusCount<=0
        pbCureStatus
      else
        pbContinueStatus
        if !move.usableWhenAsleep?   # Snore/Sleep Talk
          @lastMoveFailed = true
          return false
        end
      end
    end
    # Obedience check
    return false if !pbObedienceCheck?(choice)
    # Truant
    if hasActiveAbility?(:TRUANT)
      @effects[PBEffects::Truant] = !@effects[PBEffects::Truant]
      if !@effects[PBEffects::Truant] && !move.statusMove?   # True means loafing, but was just inverted
        @battle.pbShowAbilitySplash(self)
        @battle.pbDisplay(_INTL("{1} is loafing around!",pbThis))
        @lastMoveFailed = true
        @battle.pbHideAbilitySplash(self)
        return false
      end
    end
    # Flinching
    if @effects[PBEffects::Flinch]
      if @battle.field.field_effects == :Swamp
        @battle.pbDisplay(_INTL("The swamp shifted under {1} and they couldn't move!",pbThis))
      else
        @battle.pbDisplay(_INTL("{1} flinched and couldn't move!",pbThis))
      end
      if abilityActive?
        Battle::AbilityEffects.triggerOnFlinch(self.ability,self,@battle)
      end
      @lastMoveFailed = true
      return false
    end
    # Confusion
    if @effects[PBEffects::Confusion]>0
      @effects[PBEffects::Confusion] -= 1
      if @effects[PBEffects::Confusion]<=0
        pbCureConfusion
        @battle.pbDisplay(_INTL("{1} snapped out of its confusion.",pbThis))
      else
        @battle.pbCommonAnimation("Confusion",self)
        @battle.pbDisplay(_INTL("{1} is confused!",pbThis))
        threshold = (Settings::MECHANICS_GENERATION >= 7) ? 33 : 50   # % chance
        if @battle.pbRandom(100)<threshold
          pbConfusionDamage(_INTL("It hurt itself in its confusion!"))
          @lastMoveFailed = true
          return false
        end
      end
    end
    # Paralysis
    if @status == :PARALYSIS
      if @battle.pbRandom(100)<25
        pbContinueStatus
        @lastMoveFailed = true
        return false
      end
    end
    # Infatuation
    if @effects[PBEffects::Attract]>=0
      @battle.pbCommonAnimation("Attract",self)
      @battle.pbDisplay(_INTL("{1} is in love with {2}!",pbThis,
         @battle.battlers[@effects[PBEffects::Attract]].pbThis(true)))
      if @battle.pbRandom(100)<50
        @battle.pbDisplay(_INTL("{1} is immobilized by love!",pbThis))
        @lastMoveFailed = true
        return false
      end
    end
    return true
  end
  def pbSuccessCheckAgainstTarget(move, user, target, targets)
    show_message = move.pbShowFailMessages?(targets)
    typeMod = move.pbCalcTypeMod(move.calcType, user, target)
    target.damageState.typeMod = typeMod
    # Two-turn attacks can't fail here in the charging turn
    return true if user.effects[PBEffects::TwoTurnAttack]
    # Move-specific failures
    return false if move.pbFailsAgainstTarget?(user, target, show_message)
    # Immunity to priority moves because of Psychic Terrain
    if @battle.field.terrain == :Psychic && target.affectedByTerrain? && target.opposes?(user) &&
       @battle.choices[user.index][4] > 0   # Move priority saved from pbCalculatePriority
      @battle.pbDisplay(_INTL("{1} surrounds itself with psychic terrain!", target.pbThis)) if show_message
      return false
    end
    # Crafty Shield
    if target.pbOwnSide.effects[PBEffects::CraftyShield] && user.index != target.index &&
       move.statusMove? && !move.pbTarget(user).targets_all
      if show_message
        @battle.pbCommonAnimation("CraftyShield", target)
        @battle.pbDisplay(_INTL("Crafty Shield protected {1}!", target.pbThis(true)))
      end
      target.damageState.protected = true
      @battle.successStates[user.index].protected = true
      return false
    end
    if !(user.hasActiveAbility?(:UNSEENFIST) && move.contactMove?)
      # Wide Guard
      if target.pbOwnSide.effects[PBEffects::WideGuard] && user.index != target.index &&
         move.pbTarget(user).num_targets > 1 &&
         (Settings::MECHANICS_GENERATION >= 7 || move.damagingMove?)
        if show_message
          @battle.pbCommonAnimation("WideGuard", target)
          @battle.pbDisplay(_INTL("Wide Guard protected {1}!", target.pbThis(true)))
        end
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      end
      if move.canProtectAgainst?
        # Quick Guard
        if target.pbOwnSide.effects[PBEffects::QuickGuard] &&
           @battle.choices[user.index][4] > 0   # Move priority saved from pbCalculatePriority
          if show_message
            @battle.pbCommonAnimation("QuickGuard", target)
            @battle.pbDisplay(_INTL("Quick Guard protected {1}!", target.pbThis(true)))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          return false
        end
        # Protect
        if target.effects[PBEffects::Protect]
          if show_message
            @battle.pbCommonAnimation("Protect", target)
            @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          return false
        end
        # King's Shield
        if target.effects[PBEffects::KingsShield] && move.damagingMove?
          if show_message
            @battle.pbCommonAnimation("KingsShield", target)
            @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          if move.pbContactMove?(user) && user.affectedByContactEffect? &&
             user.pbCanLowerStatStage?(:ATTACK, target)
            user.pbLowerStatStage(:ATTACK, (Settings::MECHANICS_GENERATION >= 8) ? 1 : 2, target)
          end
          return false
        end
        # Spiky Shield
        if target.effects[PBEffects::SpikyShield]
          if show_message
            @battle.pbCommonAnimation("SpikyShield", target)
            @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          if move.pbContactMove?(user) && user.affectedByContactEffect?
            @battle.scene.pbDamageAnimation(user)
            user.pbReduceHP(user.totalhp / 8, false)
            @battle.pbDisplay(_INTL("{1} was hurt!", user.pbThis))
            user.pbItemHPHealCheck
          end
          return false
        end
        # Baneful Bunker
        if target.effects[PBEffects::BanefulBunker]
          if show_message
            @battle.pbCommonAnimation("BanefulBunker", target)
            @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          if move.pbContactMove?(user) && user.affectedByContactEffect? &&
             user.pbCanPoison?(target, false)
            user.pbPoison(target)
          end
          return false
        end
        # Obstruct
        if target.effects[PBEffects::Obstruct] && move.damagingMove?
          if show_message
            @battle.pbCommonAnimation("Obstruct", target)
            @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
          end
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          if move.pbContactMove?(user) && user.affectedByContactEffect? &&
             user.pbCanLowerStatStage?(:DEFENSE, target)
            user.pbLowerStatStage(:DEFENSE, 2, target)
          end
          return false
        end
        # Mat Block
        if target.pbOwnSide.effects[PBEffects::MatBlock] && move.damagingMove?
          # NOTE: Confirmed no common animation for this effect.
          @battle.pbDisplay(_INTL("{1} was blocked by the kicked-up mat!", move.name)) if show_message
          target.damageState.protected = true
          @battle.successStates[user.index].protected = true
          return false
        end
      end
    end
    # Magic Coat/Magic Bounce
    if move.statusMove? && move.canMagicCoat? && !target.semiInvulnerable? && target.opposes?(user)
      if target.effects[PBEffects::MagicCoat]
        target.damageState.magicCoat = true
        target.effects[PBEffects::MagicCoat] = false
        return false
      end
      if (target.hasActiveAbility?(:MAGICBOUNCE) || target.hasActiveItem?(:MAGICBOUNCEORB)) && !@battle.moldBreaker &&
         !target.effects[PBEffects::MagicBounce]
        target.damageState.magicBounce = true
        target.effects[PBEffects::MagicBounce] = true
        return false
      end
    end
    # Immunity because of ability (intentionally before type immunity check)
    return false if move.pbImmunityByAbility(user, target, show_message)
    # Type immunity
    if move.pbDamagingMove? && Effectiveness.ineffective?(typeMod)
      PBDebug.log("[Target immune] #{target.pbThis}'s type immunity")
      @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
      return false
    end
    # Dark-type immunity to moves made faster by Prankster
    if Settings::MECHANICS_GENERATION >= 7 && user.effects[PBEffects::Prankster] &&
       target.pbHasType?(:DARK) && target.opposes?(user)
      PBDebug.log("[Target immune] #{target.pbThis} is Dark-type and immune to Prankster-boosted moves")
      @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
      return false
    end
    # Airborne-based immunity to Ground moves
    if move.damagingMove? && move.calcType == :GROUND &&
       target.airborne? && !move.hitsFlyingTargets?
      if target.hasActiveAbility?(:LEVITATE) && !@battle.moldBreaker
        if show_message
          @battle.pbShowAbilitySplash(target)
          if Battle::Scene::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis))
          else
            @battle.pbDisplay(_INTL("{1} avoided the attack with {2}!", target.pbThis, target.abilityName))
          end
          @battle.pbHideAbilitySplash(target)
        end
        return false
      end
      if target.hasActiveItem?(:LEVITATEORB) && !@battle.moldBreaker
        if show_message
          ability = target.ability
          target.ability = :LEVITATE
          @battle.pbShowAbilitySplash(target)
          if Battle::Scene::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis))
          else
            @battle.pbDisplay(_INTL("{1} avoided the attack with {2}!", target.pbThis, target.abilityName))
          end
          @battle.pbHideAbilitySplash(target)
          target.ability = ability
        end
        return false
      end
      if target.hasActiveItem?(:AIRBALLOON)
        @battle.pbDisplay(_INTL("{1}'s {2} makes Ground moves miss!", target.pbThis, target.itemName)) if show_message
        return false
      end
      if target.effects[PBEffects::MagnetRise] > 0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Magnet Rise!", target.pbThis)) if show_message
        return false
      end
      if target.effects[PBEffects::Telekinesis] > 0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Telekinesis!", target.pbThis)) if show_message
        return false
      end
    end
    # Immunity to powder-based moves
    if move.powderMove?
      if target.pbHasType?(:GRASS) && Settings::MORE_TYPE_EFFECTS
        PBDebug.log("[Target immune] #{target.pbThis} is Grass-type and immune to powder-based moves")
        @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
        return false
      end
      if Settings::MECHANICS_GENERATION >= 6
        if target.hasActiveAbility?(:OVERCOAT) && !@battle.moldBreaker
          if show_message
            @battle.pbShowAbilitySplash(target)
            if Battle::Scene::USE_ABILITY_SPLASH
              @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
            else
              @battle.pbDisplay(_INTL("It doesn't affect {1} because of its {2}.", target.pbThis(true), target.abilityName))
            end
            @battle.pbHideAbilitySplash(target)
          end
          return false
        end
        if target.hasActiveItem?(:SAFETYGOGGLES)
          PBDebug.log("[Item triggered] #{target.pbThis} has Safety Goggles and is immune to powder-based moves")
          @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
          return false
        end
      end
    end
    # Substitute
    if target.effects[PBEffects::Substitute] > 0 && move.statusMove? &&
       !move.ignoresSubstitute?(user) && user.index != target.index
      PBDebug.log("[Target immune] #{target.pbThis} is protected by its Substitute")
      @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis(true))) if show_message
      return false
    end
    return true
  end
  def airborne?
    return false if hasActiveItem?(:IRONBALL)
    return false if @effects[PBEffects::Ingrain]
    return false if @effects[PBEffects::SmackDown]
    return false if @battle.field.effects[PBEffects::Gravity] > 0
    return true if pbHasType?(:FLYING)
    return true if hasActiveAbility?(:LEVITATE) && !@battle.moldBreaker
    return true if hasActiveItem?(:LEVITATEORB) && !@battle.moldBreaker
    return true if hasActiveItem?(:AIRBALLOON)
    return true if @effects[PBEffects::MagnetRise] > 0
    return true if @effects[PBEffects::Telekinesis] > 0
    return false
  end
  def takesSandstormDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:GROUND) || pbHasType?(:ROCK) || pbHasType?(:STEEL)
    return false if inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderground",
                                     "TwoTurnAttackInvulnerableUnderwater")
    return false if hasActiveAbility?([:OVERCOAT, :SANDFORCE, :SANDRUSH, :SANDVEIL, :SCALER])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end

  def takesAcidRainDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:POISON) || pbHasType?(:STEEL)
    return false if inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderground",
                                     "TwoTurnAttackInvulnerableUnderwater")
    return false if hasActiveAbility?([:OVERCOAT, :POISONHEAL, :IMMUNITY, :POISONPOINT, :POISONTOUCH])
    return false if hasActiveItem?([:SAFETYGOGGLES,:UTILITYUMBRELLA])
    return true
  end

  def takesHailDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:ICE)
    return false if inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderground",
                                     "TwoTurnAttackInvulnerableUnderwater")
    return false if hasActiveAbility?([:OVERCOAT, :ICEBODY, :SNOWCLOAK, :DEFROST])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  def takesLavaDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:WATER) || pbHasType?(:FIRE) || pbHasType?(:FLYING) || pbHasType?(:GROUND) || pbHasType?(:DRAGON)
    return false if hasActiveAbility?([:LEVITATE, :FLASHFIRE, :FLAMEBODY, :MAGMAARMOR, :HEATPROOF, :THICKFAT])
    return false if airborne?
    return true
  end
  def affectedByFumes?
    return false if pbHasType?(:POISON) || pbHasType?(:DARK) || pbHasType?(:PSYCHIC) || pbHasType?(:STEEL)
    return false if hasActiveAbility?([:OVERCOAT, :IMMUNITY, :OWNTEMPO, :TOXICBOOST, :POISONHEAL, :INNERFOCUS, :COMPOUNDEYES, :FILTER])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  def affectedByCinders?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:FIRE) || pbHasType?(:WATER)
    return false if hasActiveAbility?([:OVERCOAT, :FLASHFIRE, :FLAMEBODY, :MAGMAARMOR, :HEATPROOF, :THICKFAT])
    return false if hasActiveItem?([:SAFETYGOGGLES, :UTILITYUMBRELLA])
    return true
  end
  def affectedBySwamp?
    return false if hasActiveAbility?([:LEVITATE, :SHIELDDUST])
    return false if hasActiveItem?([:HEAVYDUTYBOOTS])
    return false if airborne?
    return true
  end
  def affectedByRuins?
    if pbHasType?(:FIRE) || pbHasType?(:WATER) || pbHasType?(:GRASS) || pbHasType?(:GHOST) || pbHasType?(:DRAGON)
      return true
    else
      return false
    end
  end
  def affectedByGarden?
    if pbHasType?(:FAIRY) || pbHasType?(:GRASS) || pbHasType?(:BUG)
      return true
    else
      return false
    end
  end
  def pbEffectsOnMakingHit(move, user, target)
    if target.damageState.calcDamage > 0 && !target.damageState.substitute
      # Target's ability
      if target.abilityActive?(true)
        oldHP = user.hp
        Battle::AbilityEffects.triggerOnBeingHit(target.ability, user, target, move, @battle)
        user.pbItemHPHealCheck if user.hp < oldHP
      end
      if user.effectiveField == :Swamp && move.physicalMove? && move.type != :GROUND && !user.pbHasType?([:POISON,:WATER,:BUG])
        @battle.scene.pbDamageAnimation(user)
        @battle.pbDisplay(_INTL("{1} struggled to move and hurt itself a little.",user.name))
        user.hp -= user.totalhp/8
      elsif user.effectiveField == :Swamp && move.type == :GROUND
        target.pbFlinch
      end
      # Cramorant - Gulp Missile
      if target.isSpecies?(:CRAMORANT) && target.ability == :GULPMISSILE &&
         target.form > 0 && !target.effects[PBEffects::Transform]
        oldHP = user.hp
        # NOTE: Strictly speaking, an attack animation should be shown (the
        #       target Cramorant attacking the user) and the ability splash
        #       shouldn't be shown.
        @battle.pbShowAbilitySplash(target)
        if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
          @battle.scene.pbDamageAnimation(user)
          user.pbReduceHP(user.totalhp / 4, false)
        end
        case target.form
        when 1   # Gulping Form
          user.pbLowerStatStageByAbility(:DEFENSE, 1, target, false)
        when 2   # Gorging Form
          target.pbParalyze(user) if target.pbCanParalyze?(user, false)
        end
        @battle.pbHideAbilitySplash(target)
        user.pbItemHPHealCheck if user.hp < oldHP
      end
      # User's ability
      if user.abilityActive?(true)
        Battle::AbilityEffects.triggerOnDealingHit(user.ability, user, target, move, @battle)
        user.pbItemHPHealCheck
      end
      # Target's item
      if target.itemActive?(true)
        oldHP = user.hp
        Battle::ItemEffects.triggerOnBeingHit(target.item, user, target, move, @battle)
        user.pbItemHPHealCheck if user.hp < oldHP
      end
    end
    if target.opposes?(user)
      # Rage
      if target.effects[PBEffects::Rage] && !target.fainted? &&
         target.pbCanRaiseStatStage?(:ATTACK, target)
        @battle.pbDisplay(_INTL("{1}'s rage is building!", target.pbThis))
        target.pbRaiseStatStage(:ATTACK, 1, target)
      end
      # Beak Blast
      if target.effects[PBEffects::BeakBlast]
        PBDebug.log("[Lingering effect] #{target.pbThis}'s Beak Blast")
        if move.pbContactMove?(user) && user.affectedByContactEffect? &&
           target.pbCanBurn?(user, false, self)
          target.pbBurn(user)
        end
      end
      # Shell Trap (make the trapper move next if the trap was triggered)
      if target.effects[PBEffects::ShellTrap] && move.physicalMove? &&
         @battle.choices[target.index][0] == :UseMove && !target.movedThisRound? &&
         target.damageState.hpLost > 0 && !target.damageState.substitute
        target.tookPhysicalHit              = true
        target.effects[PBEffects::MoveNext] = true
        target.effects[PBEffects::Quash]    = 0
      end
      # Grudge
      if target.effects[PBEffects::Grudge] && target.fainted?
        move.pp = 0
        @battle.pbDisplay(_INTL("{1}'s {2} lost all of its PP due to the grudge!",
                                user.pbThis, move.name))
      end
      # Destiny Bond (recording that it should apply)
      if target.effects[PBEffects::DestinyBond] && target.fainted? &&
         user.effects[PBEffects::DestinyBondTarget] < 0
        user.effects[PBEffects::DestinyBondTarget] = target.index
      end
    end
  end
  def effectiveField
    ret = @battle.field.field_effects
    return ret
  end
end

class Battle
  def pbEntryHazards(battler)
    battler_side = battler.pbOwnSide
    # Stealth Rock
    if battler_side.effects[PBEffects::StealthRock] && battler.takesIndirectDamage? &&
       GameData::Type.exists?(:ROCK) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS) && !battler.hasActiveAbility?(:SCALER)
      bTypes = battler.pbTypes(true)
      eff = Effectiveness.calculate(:ROCK, bTypes[0], bTypes[1], bTypes[2])
      if !Effectiveness.ineffective?(eff)
        eff = eff.to_f / Effectiveness::NORMAL_EFFECTIVE
        battler.pbReduceHP(battler.totalhp * eff / 8, false)
        pbDisplay(_INTL("Pointed stones dug into {1}!", battler.pbThis))
        battler.pbItemHPHealCheck
      end
    end
    # Spikes
    if battler_side.effects[PBEffects::Spikes] > 0 && battler.takesIndirectDamage? &&
       !battler.airborne? && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      spikesDiv = [8, 6, 4][battler_side.effects[PBEffects::Spikes] - 1]
      battler.pbReduceHP(battler.totalhp / spikesDiv, false)
      pbDisplay(_INTL("{1} is hurt by the spikes!", battler.pbThis))
      battler.pbItemHPHealCheck
    end
    # Toxic Spikes
    if battler_side.effects[PBEffects::ToxicSpikes] > 0 && !battler.fainted? && !battler.airborne?
      if battler.pbHasType?(:POISON)
        battler_side.effects[PBEffects::ToxicSpikes] = 0
        pbDisplay(_INTL("{1} absorbed the poison spikes!", battler.pbThis))
      elsif battler.pbCanPoison?(nil, false) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
        if battler_side.effects[PBEffects::ToxicSpikes] == 2
          battler.pbPoison(nil, _INTL("{1} was badly poisoned by the poison spikes!", battler.pbThis), true)
        else
          battler.pbPoison(nil, _INTL("{1} was poisoned by the poison spikes!", battler.pbThis))
        end
      end
    end
    # Sticky Web
    if battler_side.effects[PBEffects::StickyWeb] && !battler.fainted? && !battler.airborne? &&
       !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      pbDisplay(_INTL("{1} was caught in a sticky web!", battler.pbThis))
      if battler.pbCanLowerStatStage?(:SPEED)
        battler.pbLowerStatStage(:SPEED, 1, nil)
        battler.pbItemStatRestoreCheck
      end
    end
    if battler.effectiveField == :Swamp && battler.affectedBySwamp? && !battler.pbHasType?([:WATER,:POISON,:BUG])
      pbDisplay(_INTL("{1} was stuck in the swamp!", battler.pbThis))
      if battler.pbCanLowerStatStage?(:SPEED)
        battler.pbLowerStatStage(:SPEED, 1, nil)
        battler.pbItemStatRestoreCheck
      end
    end
  end
end
Battle::AbilityEffects::MoveImmunity.add(:SCALER,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if type!=:ROCK
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)


Battle::AbilityEffects::OnSwitchIn.add(:HAUNTED,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :GHOST
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is possessed!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:AMPLIFIER,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :SOUND
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is enveloped in sound!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SHADOWGUARD,
  proc { |ability,battler,battle|
    battler.effects[PBEffects::Type3] = :DARK
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is shrouded in the shadows!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ILLUMINATE,
  proc { |ability, battler, battle, switch_in|
    battler.pbRaiseStatStageByAbility(:ACCURACY, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:CACOPHONY,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is creating an uproar!",battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)
Battle::AbilityEffects::OnSwitchIn.add(:GAIAFORCE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is gathering the power of the earth!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FORESTSSECRETS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:HORSEPOWER,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:PIKAPOW,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 2
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:COMPOSURE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 2 if move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SURVIVALINSTINCT,
  proc { |ability, user, target, move, mults, baseDmg, type|
    if !target.hasActiveAbility?(:HUNTERSINSTINCT)
      mults[:final_damage_multiplier] /= 2 if Effectiveness.normal?(target.damageState.typeMod)
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:HUNTERSINSTINCT,
  proc { |ability, user, target, move, mults, baseDmg, type|
    if !target.hasActiveAbility?(:SURVIVALINSTINCT)
      mults[:final_damage_multiplier] *= 2 if Effectiveness.resistant?(target.damageState.typeMod)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:HUNTERSINSTINCT,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if battle.pbCheckGlobalAbility(:SURVIVALINSTINCT)
      battle.pbDisplay(_INTL("Both Instincts were neutralized!"))
    else
      battle.pbDisplay(_INTL("{1}'s has the {2}!", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SURVIVALINSTINCT,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if battle.pbCheckGlobalAbility(:HUNTERSINSTINCT)
      battle.pbDisplay(_INTL("Both Instincts were neutralized!"))
    else
      battle.pbDisplay(_INTL("{1}'s has the {2}!", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::Instinct.add(:HUNTERSINSTINCT,
  proc { |ability, battler, battle, endOfBattle|
    next if endOfBattle
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}'s {2} has returned!",battler.pbThis,battler.abilityName))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::Instinct.add(:SURVIVALINSTINCT,
  proc { |ability, battler, battle, endOfBattle|
    next if endOfBattle
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}'s {2} has returned!",battler.pbThis,battler.abilityName))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:GROWTHINSTINCT,
  proc { |ability, battler, battle, switch_in|
    oAtk = oSpA = 0
    battle.allOtherSideBattlers(battler.index).each do |b|
      oAtk   += b.attack
      oSpA += b.spatk
    end
    stat = (oAtk > oSpA) ? :DEFENSE : :SPECIAL_DEFENSE
    battler.pbRaiseStatStageByAbility(stat, 1, battler)
  }
)

Battle::AbilityEffects::StatusImmunity.add(:FAIRYBUBBLE,
  proc { |ability, battler, status|
    next true if status != :NONE
  }
)

Battle::AbilityEffects::StatusCure.add(:FAIRYBUBBLE,
  proc { |ability, battler|
    next if battler.status == :NONE
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("{1}'s {2} healed its status!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FAIRYBUBBLE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 2 if type == :FAIRY
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FAIRYBUBBLE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:final_damage_multiplier] /= 2 if type == :POISON
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:FAIRYBUBBLE,
  proc { |ability, battler, endOfBattle|
    next if battler.status == :NONE
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:GRASSYSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Grassy
    next if battler.effectiveField == :Garden
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Grassy)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:BADDREAMS,
  proc { |ability, battler, battle, switch_in|
    oDef = oSpDef = 0
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.effects[PBEffects::Yawn] = 2
      battle.pbDisplay(INTL("{1} became drowsy!",b.pbThis))
      b.pbSleepDuration(2)
      b.effects[PBEffects::Nightmare] = true
    end
  }
)

Battle::AbilityEffects::MoveImmunity.add(:PIKAPOW,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if type!=:GROUND
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!",
           target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.copy(:PIKAPOW,:AMPEDUP)

Battle::AbilityEffects::StatusImmunity.copy(:PURIFYINGSALT,:CLEANWATER)