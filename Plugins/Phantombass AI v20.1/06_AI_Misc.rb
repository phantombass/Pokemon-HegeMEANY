def deep_copy(obj)
  Marshal.load(Marshal.dump(obj))
end

def pbHashConverter(mod,hash)
  newhash = {}
  hash.each {|key, value|
      for i in value
          newhash[mod.const_get(i.to_sym)]=key
      end
  }
  return newhash
end

def pbHashForwardizer(hash) #one-stop shop for your hash debackwardsing needs!
  return if !hash.is_a?(Hash)
  newhash = {}
  hash.each {|key, value|
      for i in value
          newhash[i]=key
      end
  }
  return newhash
end

def arrayToConstant(mod,array)
  newarray = []
  for symbol in array
    const = mod.const_get(symbol.to_sym) rescue nil
    newarray.push(const) if const
  end
  return newarray
end

def hashToConstant(mod,hash)
  for key in hash.keys
    const = mod.const_get(hash[key].to_sym) rescue nil
    hash.merge!(key=>const) if const
  end
  return hash
end

def hashArrayToConstant(mod,hash)
  for key in hash.keys
    array = hash[key]
    newarray = arrayToConstant(mod,array)
    hash.merge!(key=>newarray) if !newarray.empty?
  end
  return hash
end

Essentials::ERROR_TEXT += "[Phantombass AI v#{Phantombass_AI::VERSION}]\r\n"

=begin
STATUSTEXTS = ["status", "sleep", "poison", "burn", "paralysis", "ice"]
STATSTRINGS = ["HP", "Attack", "Defense", "Speed", "Sp. Attack", "Sp. Defense"]

class PBStuff
  #rejuv stuff while we work out the kinks
  #massive arrays of stuff that no one wants to see
  #List of Abilities that either prevent or co-opt Intimidate
  TRACEABILITIES = arrayToConstant(GameData::Ability,[:PROTEAN,:CONTRARY,:INTIMIDATE, :WONDERGUARD,:MAGICGUARD,
    :SWIFTSWIM,:SLUSHRUSH, :SANDRUSH,:TELEPATHY,:SURGESURFER, :SOLARPOWER,:DRYSKIN,:DOWNLOAD, :LEVITATE,
    :LIGHTNINGROD,:MOTORDRIVE, :VOLTABSORB,:FLASHFIRE,:MAGMAARMOR, :ADAPTABILITY,:DEFIANT,:COMPETITIVE, 
    :PRANKSTER,:SPEEDBOOST,:MULTISCALE, :SHADOWSHIELD,:SAPSIPPER,:FURCOAT, :FLUFFY,:MAGICBOUNCE,
    :REGENERATOR, :DAZZLING,:QUEENLYMAJESTY,:SOUNDPROOF, :TECHNICIAN,:SPEEDBOOST,:STEAMENGINE, 
    :ICESCALES,:BEASTBOOST,:SHEDSKIN, :CLEARBODY,:WHITESMOKE,:MOODY, :THICKFAT,:STORMDRAIN,
    :SIMPLE,:PUREPOWER,:MARVELSCALE,:STURDY,:MEGALAUNCHER,:LIBERO,:SHEERFORCE,:UNAWARE,:CHLOROPHYLL])
  NEGATIVEABILITIES = arrayToConstant(GameData::Ability,[:TRUANT,:DEFEATIST,:SLOWSTART,:KLUTZ,:STALL,:GORILLATACTICS,:RIVALRY])

#Standardized lists of moves or abilities which are sometimes called
  #Blacklisted abilities USUALLY can't be copied.
###--------------------------------------ABILITYBLACKLIST-------------------------------------------------------###
ABILITYBLACKLIST = arrayToConstant(GameData::Ability,[:MULTITYPE, :COMATOSE,:DISGUISE, :SCHOOLING, 
  :RKSSYSTEM, :IMPOSTER,:SHIELDSDOWN, :POWEROFALCHEMY,:RECEIVER,:TRACE, :FORECAST, :FLOWERGIFT,
  :ILLUSION,:WONDERGUARD, :ZENMODE, :STANCECHANGE,:POWERCONSTRUCT,:ICEFACE,:MULTITOOL])

###--------------------------------------FIXEDABILITIES---------------------------------------------------------###
#Fixed abilities USUALLY can't be changed.
FIXEDABILITIES = arrayToConstant(GameData::Ability,[:MULTITYPE, :ZENMODE, :STANCECHANGE, :SCHOOLING, 
  :COMATOSE,:SHIELDSDOWN, :DISGUISE, :RKSSYSTEM, :POWERCONSTRUCT,:ICEFACE, :GULPMISSILE])

#Standardized lists of moves with similar purposes/characteristics
#(mostly just "stuff that gets called together")

###--------------------------------------UNFREEZEMOVE-----------------------------------------------------------###
UNFREEZEMOVE = arrayToConstant(GameData::Move,[:FLAMEWHEEL,:SACREDFIRE,:FLAREBLITZ, :FUSIONFLARE, 
  :SCALD, :STEAMERUPTION, :BURNUP])

###--------------------------------------SETUPMOVE--------------------------------------------------------------###
SETUPMOVE = arrayToConstant(GameData::Move,[:SWORDSDANCE, :DRAGONDANCE, :CALMMIND, :WORKUP,:NASTYPLOT, 
  :TAILGLOW,:BELLYDRUM, :BULKUP,:COIL,:CURSE, :GROWTH, :HONECLAWS, :QUIVERDANCE, :SHELLSMASH])

###--------------------------------------PROTECTMOVE------------------------------------------------------------###
PROTECTMOVE = arrayToConstant(GameData::Move,[:PROTECT, :DETECT,:KINGSSHIELD, :SPIKYSHIELD, :BANEFULBUNKER])

###--------------------------------------PROTECTIGNORINGMOVE----------------------------------------------------###
PROTECTIGNORINGMOVE = arrayToConstant(GameData::Move,[:FEINT, :HYPERSPACEHOLE,:HYPERSPACEFURY, :SHADOWFORCE, :PHANTOMFORCE])

###--------------------------------------SCREENBREAKERMOVE------------------------------------------------------###
SCREENBREAKERMOVE = arrayToConstant(GameData::Move,[:DEFOG, :BRICKBREAK,:PSYCHICFANGS])

###--------------------------------------CONTRARYBAITMOVE-------------------------------------------------------###
CONTRARYBAITMOVE = arrayToConstant(GameData::Move,[:SUPERPOWER,:OVERHEAT,:DRACOMETEOR, :LEAFSTORM, 
  :FLEURCANNON, :PSYCHOBOOST])

###--------------------------------------TWOTURNAIRMOVE---------------------------------------------------------###
TWOTURNAIRMOVE = arrayToConstant(GameData::Move,[:BOUNCE,:FLY, :SKYDROP])

###--------------------------------------PIVOTMOVE--------------------------------------------------------------###
PIVOTMOVE = arrayToConstant(GameData::Move,[:UTURN, :VOLTSWITCH,:PARTINGSHOT,:CHILLYRECEPTION,:SHEDTAIL,:FLIPTURN,:TELEPORT])

###--------------------------------------DANCEMOVE--------------------------------------------------------------###
DANCEMOVE = arrayToConstant(GameData::Move,[:QUIVERDANCE, :DRAGONDANCE, :FIERYDANCE, 
  :FEATHERDANCE,:PETALDANCE,:SWORDSDANCE, :TEETERDANCE, :LUNARDANCE,:REVELATIONDANCE])

###--------------------------------------BULLETMOVE-------------------------------------------------------------###
BULLETMOVE = arrayToConstant(GameData::Move,[:ACIDSPRAY, :AURASPHERE,:BARRAGE, :BULLETSEED,
  :EGGBOMB, :ELECTROBALL, :ENERGYBALL, :FOCUSBLAST,:GYROBALL,:ICEBALL, :MAGNETBOMB, 
  :MISTBALL,:MUDBOMB, :OCTAZOOKA, :ROCKWRECKER, :SEARINGSHOT, :SEEDBOMB,:SHADOWBALL,
  :SLUDGEBOMB, :WEATHERBALL, :ZAPCANNON, :BEAKBLAST])

###--------------------------------------BITEMOVE---------------------------------------------------------------###
BITEMOVE = arrayToConstant(GameData::Move,[:BITE,:CRUNCH,:THUNDERFANG, :FIREFANG,:ICEFANG,
  :POISONFANG,:HYPERFANG, :PSYCHICFANGS, :COSMICFANGS, :DRACOFANGS, :IRONFANGS, :LEECHLIFE])

###--------------------------------------PHASEMOVE--------------------------------------------------------------###
PHASEMOVE = arrayToConstant(GameData::Move,[:ROAR,:WHIRLWIND, :CIRCLETHROW, :DRAGONTAIL,:YAWN,:PERISHSONG])

###--------------------------------------SCREENMOVE-------------------------------------------------------------###
SCREENMOVE = arrayToConstant(GameData::Move,[:LIGHTSCREEN, :REFLECT, :AURORAVEIL])

###--------------------------------------OHKOMOVE-------------------------------------------------------------###
OHKOMOVE = arrayToConstant(GameData::Move,[:FISSURE,:SHEERCOLD,:GUILLOTINE,:HORNDRILL])

#Moves that inflict statuses with at least a 50% of hitting
###--------------------------------------BURNMOVE---------------------------------------------------------------###
BURNMOVE = arrayToConstant(GameData::Move,[:WILLOWISP, :SACREDFIRE,:INFERNO])

###--------------------------------------PARAMOVE---------------------------------------------------------------###
PARAMOVE = arrayToConstant(GameData::Move,[:THUNDERWAVE, :STUNSPORE, :GLARE, :NUZZLE,:ZAPCANNON])

###--------------------------------------SLEEPMOVE--------------------------------------------------------------###
SLEEPMOVE = arrayToConstant(GameData::Move,[:SPORE, :SLEEPPOWDER, :HYPNOSIS, :DARKVOID,:GRASSWHISTLE,
  :LOVELYKISS,:SING, :YAWN])

###--------------------------------------POISONMOVE-------------------------------------------------------------###
POISONMOVE = arrayToConstant(GameData::Move,[:TOXIC, :POISONPOWDER,:POISONGAS, :TOXICTHREAD])

###--------------------------------------CONFUMOVE--------------------------------------------------------------###
CONFUMOVE = arrayToConstant(GameData::Move,[:CONFUSERAY,:SUPERSONIC,:FLATTER, :SWAGGER, :SWEETKISS, 
  :TEETERDANCE, :CHATTER, :DYNAMICPUNCH])

#all the status inflicting moves
###--------------------------------------STATUSCONDITIONMOVE----------------------------------------------------###
STATUSCONDITIONMOVE = arrayToConstant(GameData::Move,[:WILLOWISP, :DARKVOID,:GRASSWHISTLE, :HYPNOSIS,
  :LOVELYKISS,:SING,:SLEEPPOWDER, :SPORE, :YAWN,:POISONGAS, :POISONPOWDER, :TOXIC, :NUZZLE,
  :STUNSPORE, :THUNDERWAVE, :DEEPFREEZE])


#Odd groups of moves/effects with similar behavior
###--------------------------------------HEALFUNCTIONS----------------------------------------------------------###
HEALFUNCTIONS =["0D5","0D6","0D7","0D8","0D9","0DD","0DE","0DF",
  "0E3","0E4","114","139","158","162","169","16C","172"]

###--------------------------------------RATESHARERS------------------------------------------------------------###
RATESHARERS = arrayToConstant(GameData::Move,[:PROTECT, :DETECT,:QUICKGUARD, :WIDEGUARD, :ENDURE,
  :KINGSSHIELD, :SPIKYSHIELD, :BANEFULBUNKER, :CRAFTYSHIELD, :OBSTRUCT])

###--------------------------------------INVULEFFECTS-----------------------------------------------------------###
INVULEFFECTS = arrayToConstant(PBEffects,[:Protect, :Endure,:Obstruct, :KingsShield, :SpikyShield, :MatBlock, 
  :BanefulBunker])

###--------------------------------------POWDERMOVES------------------------------------------------------------###
POWDERMOVES = arrayToConstant(GameData::Move,[:COTTONSPORE, :SLEEPPOWDER, :STUNSPORE, :SPORE, :RAGEPOWDER,
  :POISONPOWDER,:POWDER])

###--------------------------------------AIRHITMOVES------------------------------------------------------------###
AIRHITMOVES = arrayToConstant(GameData::Move,[:THUNDER, :HURRICANE, :GUST, :TWISTER, :SKYUPPERCUT, 
  :SMACKDOWN, :THOUSANDARROWS])

# Blacklist stuff
###--------------------------------------NOCOPYMOVE-------------------------------------------------------------###
NOCOPYMOVE = arrayToConstant(GameData::Move,[:ASSIST,:COPYCAT, :MEFIRST, :METRONOME, :MIMIC, :MIRRORMOVE,
  :NATUREPOWER, :SHELLTRAP, :SKETCH,:SLEEPTALK, :STRUGGLE, :BEAKBLAST, :FOCUSPUNCH,:TRANSFORM, 
  :BELCH, :CHATTER, :KINGSSHIELD, :BANEFULBUNKER, :BESTOW, :COUNTER, :COVET, :DESTINYBOND, :DETECT, 
  :ENDURE,:FEINT, :FOLLOWME,:HELPINGHAND, :MATBLOCK,:MIRRORCOAT,:PROTECT, :RAGEPOWDER, :SNATCH,
  :SPIKYSHIELD, :SPOTLIGHT, :SWITCHEROO, :THIEF, :TRICK])

###--------------------------------------NOAUTOMOVE-------------------------------------------------------------###
NOAUTOMOVE = arrayToConstant(GameData::Move,[:ASSIST,:COPYCAT, :MEFIRST, :METRONOME, :MIMIC, :MIRRORMOVE,
  :NATUREPOWER, :SHELLTRAP, :SKETCH,:SLEEPTALK, :STRUGGLE])

###--------------------------------------DELAYEDMOVE------------------------------------------------------------###
DELAYEDMOVE = arrayToConstant(GameData::Move,[:BEAKBLAST, :FOCUSPUNCH, :SHELLTRAP])

###--------------------------------------TWOTURNMOVE------------------------------------------------------------###
TWOTURNMOVE = arrayToConstant(GameData::Move,[:BOUNCE,:DIG, :DIVE, :FLY, :PHANTOMFORCE,:SHADOWFORCE, :SKYDROP])

###--------------------------------------FORCEOUTMOVE-----------------------------------------------------------###
FORCEOUTMOVE = arrayToConstant(GameData::Move,[:CIRCLETHROW, :DRAGONTAIL,:ROAR, :WHIRLWIND])
###--------------------------------------REPEATINGMOVE----------------------------------------------------------###
REPEATINGMOVE = arrayToConstant(GameData::Move,[:ICEBALL, :OUTRAGE, :PETALDANCE, :ROLLOUT, :THRASH])

###--------------------------------------CHARGEMOVE-------------------------------------------------------------###
CHARGEMOVE = arrayToConstant(GameData::Move,[:BIDE, :GEOMANCY,:RAZORWIND, :SKULLBASH,:SKYATTACK,:SOLARBEAM, 
  :SOLARBLADE, :FREEZESHOCK, :ICEBURN, :METEORSHOWER])
end

=end
class Battle
  def typesInverted?
    return $game_temp.battle_rules["inverseBattle"] == true
  end
end

module Effectiveness
  def get_resisted_types(type)
    resisted = []
    for i in types
      resisted.push(i) if self.resistant_type?(i,type)
    end
    return resisted
  end

  def get_super_effective_types(type)
    superE = []
    for i in types
      superE.push(i) if self.super_effective_type?(i,type)
    end
    return superE
  end
end

class Battle::Scene
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    battler = @battle.battlers[idxBattler]
    cw = @sprites["fightWindow"]
    cw.battler = battler
    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]]&.id
      moveIndex = @lastMove[idxBattler]
    end
    cw.shiftMode = (@battle.pbCanShift?(idxBattler)) ? 1 : 0
    cw.setIndexAndMode(moveIndex, (megaEvoPossible) ? 1 : 0)
    needFullRefresh = true
    needRefresh = false
    loop do
      # Refresh view if necessary
      if needFullRefresh
        pbShowWindow(FIGHT_BOX)
        pbSelectBattler(idxBattler)
        needFullRefresh = false
      end
      if needRefresh
        if megaEvoPossible
          newMode = (@battle.pbRegisteredMegaEvolution?(idxBattler)) ? 2 : 1
          cw.mode = newMode if newMode != cw.mode
        end
        needRefresh = false
      end
      oldIndex = cw.index
      # General update
      pbUpdate(cw)
      # Update selected command
      if Input.trigger?(Input::LEFT)
        cw.index -= 1 if (cw.index & 1) == 1
      elsif Input.trigger?(Input::RIGHT)
        if battler.moves[cw.index + 1]&.id && (cw.index & 1) == 0
          cw.index += 1
        end
      elsif Input.trigger?(Input::UP)
        cw.index -= 2 if (cw.index & 2) == 2
      elsif Input.trigger?(Input::DOWN)
        if battler.moves[cw.index + 2]&.id && (cw.index & 2) == 0
          cw.index += 2
        end
      end
      pbPlayCursorSE if cw.index != oldIndex
      # Actions
      if Input.trigger?(Input::USE)      # Confirm choice
        chosen_move = battler.moves[cw.index]
        $spam_block_flags[:same_move].push(chosen_move) if !@battle.doublebattle
        recover = ["HealUserHalfOfTotalHP", "HealUserHalfOfTotalHPLoseFlyingTypeThisTurn", "HealUserPositionNextTurn","HealUserDependingOnWeather","HealUserDependingOnSandstorm"]
        initative = ["SwitchOutTargetStatusMove", "SwitchOutTargetDamagingMove", "SwitchOutUserDamagingMove","LowerTargetAtkSpAtk1SwitchOutUser","SwitchOutUserStartHailWeather","UserMakeSubstituteSwitchOut"]
        $spam_block_flags[:double_recover].push(chosen_move) if recover.include?(chosen_move.function) && !@battle.doublebattle
        $spam_block_flags[:initiative_flag].push(chosen_move) if initative.include?(chosen_move.function) && !@battle.doublebattle
        $spam_block_flags[:protect_switch].push(chosen_move) if chosen_move.is_a?(Battle::Move::ProtectUser) && !@battle.doublebattle
        $spam_block_flags[:choice] = battler.moves[cw.index]
        $spam_block_flags[:triple_switch].clear
        pbPlayDecisionSE
        break if yield cw.index
        needFullRefresh = true
        needRefresh = true
      elsif Input.trigger?(Input::BACK)   # Cancel fight menu
        pbPlayCancelSE
        break if yield -1
        needRefresh = true
      elsif Input.trigger?(Input::ACTION)   # Toggle Mega Evolution
        if megaEvoPossible
          pbPlayDecisionSE
          break if yield -2
          needRefresh = true
        end
      elsif Input.trigger?(Input::SPECIAL)   # Shift
        if cw.shiftMode > 0
          pbPlayDecisionSE
          break if yield -3
          needRefresh = true
        end
      end
    end
    @lastMove[idxBattler] = cw.index
  end

  #=============================================================================
  # Opens the party screen to choose a Pokémon to switch in (or just view its
  # summary screens)
  # mode: 0=Pokémon command, 1=choose a Pokémon to send to the Boxes, 2=view
  #       summaries only
  #=============================================================================
  def pbPartyScreen(idxBattler, canCancel = false, mode = 0)
    # Fade out and hide all sprites
    visibleSprites = pbFadeOutAndHide(@sprites)
    # Get player's party
    partyPos = @battle.pbPartyOrder(idxBattler)
    partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
    modParty = @battle.pbPlayerDisplayParty(idxBattler)
    # Start party screen
    scene = PokemonParty_Scene.new
    switchScreen = PokemonPartyScreen.new(scene, modParty)
    msg = _INTL("Choose a Pokémon.")
    msg = _INTL("Send which Pokémon to Boxes?") if mode == 1
    switchScreen.pbStartScene(msg, @battle.pbNumPositions(0, 0))
    # Loop while in party screen
    loop do
      # Select a Pokémon
      scene.pbSetHelpText(msg)
      idxParty = switchScreen.pbChoosePokemon
      if idxParty < 0
        next if !canCancel
        break
      end
      # Choose a command for the selected Pokémon
      cmdSwitch  = -1
      cmdBoxes   = -1
      cmdSummary = -1
      commands = []
      commands[cmdSwitch  = commands.length] = _INTL("Switch In") if mode == 0 && modParty[idxParty].able?
      commands[cmdBoxes   = commands.length] = _INTL("Send to Boxes") if mode == 1
      commands[cmdSummary = commands.length] = _INTL("Summary")
      commands[commands.length]              = _INTL("Cancel")
      command = scene.pbShowCommands(_INTL("Do what with {1}?", modParty[idxParty].name), commands)
      if (cmdSwitch >= 0 && command == cmdSwitch) ||   # Switch In
         (cmdBoxes >= 0 && command == cmdBoxes)        # Send to Boxes
        idxPartyRet = -1
        partyPos.each_with_index do |pos, i|
          next if pos != idxParty + partyStart
          idxPartyRet = i
          break
        end
        $spam_block_flags[:triple_switch].push(:Switch)
        $spam_block_flags[:protect_switch].push(:Switch)
        $spam_block_flags[:fake_out_ghost_flag].push(:Switch) if (modParty[idxParty].hasType?(:GHOST) || modParty[idxParty].hasAbility?([:ARMORTAIL,:DAZZLING,:QUEENLYMAJESTY]))
        $spam_block_flags[:choice] = modParty[idxParty]
        break if yield idxPartyRet, switchScreen
      elsif cmdSummary >= 0 && command == cmdSummary   # Summary
        scene.pbSummary(idxParty, true)
      end
    end
    # Close party screen
    switchScreen.pbEndScene
    # Fade back into battle screen
    pbFadeInAndShow(@sprites, visibleSprites)
  end
end