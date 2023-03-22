module GameData
  class FieldEffects
    attr_reader :id
    attr_reader :real_name

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Unnamed"
    end

    # @return [String] the translated name of this field effect
    def name
      return _INTL(@real_name)
    end
  end
end

GameData::FieldEffects.register({
  :id   => :None,
  :name => _INTL("None")
})

GameData::FieldEffects.register({
  :id   => :Home,
  :name => _INTL("Home")
})


GameData::FieldEffects.register({
  :id        => :EchoChamber,
  :name      => _INTL("Echo Chamber"),
})

GameData::FieldEffects.register({
  :id        => :Desert,
  :name      => _INTL("Desert"),
})

GameData::FieldEffects.register({
  :id        => :Lava,
  :name      => _INTL("Lava"),
})

GameData::FieldEffects.register({
  :id        => :ToxicFumes,
  :name      => _INTL("Toxic Fumes"),
})

GameData::FieldEffects.register({
  :id        => :Fire,
  :name      => _INTL("Fire"),
})

GameData::FieldEffects.register({
  :id        => :Swamp,
  :name      => _INTL("Swamp"),
})

GameData::FieldEffects.register({
  :id        => :City,
  :name      => _INTL("City"),
})

GameData::FieldEffects.register({
  :id        => :Ruins,
  :name      => _INTL("Ruins"),
})

GameData::FieldEffects.register({
  :id        => :Garden,
  :name      => _INTL("Garden"),
})

GameData::Environment.register({
  :id   => :EchoChamber,
  :name => _INTL("Echo Chamber"),
  :battle_base => "cave2"
})

GameData::Environment.register({
  :id   => :Lava,
  :name => _INTL("Lava"),
  :battle_base => "lava"
})

GameData::Environment.register({
  :id   => :Poison,
  :name => _INTL("Poison"),
  :battle_base => "poison"
})

GameData::Environment.register({
  :id   => :Fire,
  :name => _INTL("Fire"),
  :battle_base => "fire"
})

GameData::Environment.register({
  :id   => :Swamp,
  :name => _INTL("Swamp"),
  :battle_base => "swamp"
})

GameData::Environment.register({
  :id          => :City,
  :name        => _INTL("City"),
  :battle_base => "city"
})

GameData::Environment.register({
  :id          => :Ruins,
  :name        => _INTL("Ruins"),
  :battle_base => "rocky"
})

GameData::Environment.register({
  :id          => :Garden,
  :name        => _INTL("Garden"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id          => :Home,
  :name        => _INTL("Home"),
  :battle_base => "grass_night"
})
module PBEffects
  CaennerbongDance = 117
  EchoChamber = 118
  Singed = 119
end

class Game_Temp
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "single", "1v1", "1v2", "2v1", "1v3", "3v1",
         "double", "2v2", "2v3", "3v2", "triple", "3v3"
      rules["size"] = rule.to_s.downcase
    when "canlose"                then rules["canLose"]             = true
    when "cannotlose"             then rules["canLose"]             = false
    when "canrun"                 then rules["canRun"]              = true
    when "cannotrun"              then rules["canRun"]              = false
    when "roamerflees"            then rules["roamerFlees"]         = true
    when "noexp"                  then rules["expGain"]             = false
    when "nomoney"                then rules["moneyGain"]           = false
    when "disablepokeballs"       then rules["disablePokeBalls"]    = true
    when "forcecatchintoparty"    then rules["forceCatchIntoParty"] = true
    when "switchstyle"            then rules["switchStyle"]         = true
    when "setstyle"               then rules["switchStyle"]         = false
    when "anims"                  then rules["battleAnims"]         = true
    when "noanims"                then rules["battleAnims"]         = false
    when "terrain"
      rules["defaultTerrain"] = GameData::BattleTerrain.try_get(var)&.id
    when "weather"
      rules["defaultWeather"] = GameData::BattleWeather.try_get(var)&.id
    when "field"
      rules["defaultField"] = GameData::FieldEffects.try_get(var)&.id
    when "environment", "environ"
      rules["environment"] = GameData::Environment.try_get(var)&.id
    when "backdrop", "battleback" then rules["backdrop"]            = var
    when "base"                   then rules["base"]                = var
    when "outcome", "outcomevar"  then rules["outcomeVar"]          = var
    when "nopartner"              then rules["noPartner"]           = true
    when "inversebattle"          then rules["inverseBattle"] = true
    else
      raise _INTL("Battle rule \"{1}\" does not exist.", rule)
    end
    case rules["defaultField"]
    when :None
      $game_screen.field_effect(:None)
    when :EchoChamber
      rules["environment"] = :EchoChamber
      $PokemonGlobal.nextBattleBack = "cave2"
      $game_screen.field_effect(:EchoChamber)
    when :Desert
      rules["environment"] = :Sand
      $PokemonGlobal.nextBattleBack = "sand"
      $game_screen.field_effect(:Desert)
    when :Lava
      rules["environment"] = :Lava
      $PokemonGlobal.nextBattleBack = "lava"
      $game_screen.field_effect(:Lava)
    when :ToxicFumes
      rules["environment"] = :Poison
      $PokemonGlobal.nextBattleBack = "poison"
      $game_screen.field_effect(:ToxicFumes)
    when :Fire
      rules["environment"] = :Fire
      $PokemonGlobal.nextBattleBack = "fire"
      $game_screen.field_effect(:Fire)
    when :Swamp
      rules["environment"] = :Swamp
      $PokemonGlobal.nextBattleBack = "swamp"
      $game_screen.field_effect(:Swamp)
    when :City
      rules["environment"] = :City
      $PokemonGlobal.nextBattleBack = "city"
      $game_screen.field_effect(:City)
    when :Ruins
      rules["environment"] = :Ruins
      $PokemonGlobal.nextBattleBack = "rocky"
      $game_screen.field_effect(:Ruins)
    when :Home
      rules["environment"] = :Home
      $PokemonGlobal.nextBattleBack = "forest"
      $game_screen.field_effect(:Home)
    when :Garden
      rules["environment"] = :Garden
      $PokemonGlobal.nextBattleBack = "field"
      $game_screen.field_effect(:Garden)
    end
  end
end

#-------------------------------------------------------------------------------
# Set type for 'inverse'
#-------------------------------------------------------------------------------
module GameData
	class Type
		alias inverse_effect effectiveness
		def effectiveness(other_type)
			return Effectiveness::NORMAL_EFFECTIVE_ONE if !other_type
			ret = inverse_effect(other_type)
			if $inverse
				case ret
				when 0, 1; ret = 4
				when 4;    ret = 1
				end
			end
			return ret
		end
	end
end
$inverse = false
# Set rule 'inverse'
EventHandlers.add(:on_start_battle, :inverse_battle,
  proc { |_sender| $inverse = true if $game_temp.battle_rules["inverseBattle"] }
)
EventHandlers.add(:on_end_battle, :inverse_battle_end,
  proc { |_sender,e| $inverse = false }
)

def setBattleRule(*args)
  r = nil
  args.each do |arg|
    if r
      $game_temp.add_battle_rule(r, arg)
      r = nil
    else
      case arg.downcase
      when "terrain", "weather", "environment", "environ", "backdrop",
           "battleback", "base", "outcome", "outcomevar","field"
        r = arg
        next
      end
      $game_temp.add_battle_rule(arg)
    end
  end
  raise _INTL("Argument {1} expected a variable after it but didn't have one.", r) if r
end

module BattleCreationHelperMethods
  def prepare_battle(battle)
    battleRules = $game_temp.battle_rules
    # The size of the battle, i.e. how many Pokémon on each side (default: "single")
    battle.setBattleMode(battleRules["size"]) if !battleRules["size"].nil?
    # Whether the game won't black out even if the player loses (default: false)
    battle.canLose = battleRules["canLose"] if !battleRules["canLose"].nil?
    # Whether the player can choose to run from the battle (default: true)
    battle.canRun = battleRules["canRun"] if !battleRules["canRun"].nil?
    # Whether wild Pokémon always try to run from battle (default: nil)
    battle.rules["alwaysflee"] = battleRules["roamerFlees"]
    # Whether Pokémon gain Exp/EVs from defeating/catching a Pokémon (default: true)
    battle.expGain = battleRules["expGain"] if !battleRules["expGain"].nil?
    # Whether the player gains/loses money at the end of the battle (default: true)
    battle.moneyGain = battleRules["moneyGain"] if !battleRules["moneyGain"].nil?
    # Whether Poké Balls cannot be thrown at all
    battle.disablePokeBalls = battleRules["disablePokeBalls"] if !battleRules["disablePokeBalls"].nil?
    # Whether the player is asked what to do with a new Pokémon when their party is full
    battle.sendToBoxes = $PokemonSystem.sendtoboxes if Settings::NEW_CAPTURE_CAN_REPLACE_PARTY_MEMBER
    battle.sendToBoxes = 2 if battleRules["forceCatchIntoParty"]
    # Whether the player is able to switch when an opponent's Pokémon faints
    battle.switchStyle = ($PokemonSystem.battlestyle == 0)
    battle.switchStyle = battleRules["switchStyle"] if !battleRules["switchStyle"].nil?
    # Whether battle animations are shown
    battle.showAnims = ($PokemonSystem.battlescene == 0)
    battle.showAnims = battleRules["battleAnims"] if !battleRules["battleAnims"].nil?
    # Terrain
    if battleRules["defaultTerrain"].nil? && Settings::OVERWORLD_WEATHER_SETS_BATTLE_TERRAIN
      case $game_screen.weather_type
      when :Storm
        battle.defaultTerrain = :Electric
      when :Fog
        battle.defaultTerrain = :Misty
      end
    else
      battle.defaultTerrain = battleRules["defaultTerrain"]
    end
    # Weather
    if battleRules["defaultWeather"].nil?
      case GameData::Weather.get($game_screen.weather_type).category
      when :Rain, :Storm
        battle.defaultWeather = :Rain
      when :Hail
        battle.defaultWeather = :Hail
      when :Sandstorm
        battle.defaultWeather = :Sandstorm
      when :Sun
        battle.defaultWeather = :Sun
      end
    else
      battle.defaultWeather = battleRules["defaultWeather"]
    end
    if battleRules["defaultField"].nil?
      case $game_screen.field_effects
      when :EchoChamber
        battle.defaultField = :EchoChamber
      when :Desert
        battle.defaultField = :Desert
      when :Lava
        battle.defaultField = :Lava
      when :ToxicFumes
        battle.defaultField = :ToxicFumes
      when :Fire
        battle.defaultField = :Fire
      when :Swamp
        battle.defaultField = :Swamp
      when :City
        battle.defaultField = :City
      when :Ruins
        battle.defaultField = :Ruins
      when :Garden
        battle.defaultField = :Garden
      end
    else
      battle.defaultField = battleRules["defaultField"]
    end
    # Environment
    if battleRules["environment"].nil?
      battle.environment = pbGetEnvironment
    else
      battle.environment = battleRules["environment"]
    end
    # Backdrop graphic filename
    if !battleRules["backdrop"].nil?
      backdrop = battleRules["backdrop"]
    elsif $PokemonGlobal.nextBattleBack
      backdrop = $PokemonGlobal.nextBattleBack
    elsif $PokemonGlobal.surfing
      backdrop = "water"   # This applies wherever you are, including in caves
    elsif $game_map.metadata
      back = $game_map.metadata.battle_background
      backdrop = back if back && back != ""
    end
    backdrop = "indoor1" if !backdrop
    battle.backdrop = backdrop
    # Choose a name for bases depending on environment
    if battleRules["base"].nil?
      environment_data = GameData::Environment.try_get(battle.environment)
      base = environment_data.battle_base if environment_data
    else
      base = battleRules["base"]
    end
    battle.backdropBase = base if base
    # Time of day
    if $game_map.metadata&.battle_environment == :Cave
      battle.time = 2   # This makes Dusk Balls work properly in caves
    elsif Settings::TIME_SHADING
      timeNow = pbGetTimeNow
      if PBDayNight.isNight?(timeNow)
        battle.time = 2
      elsif PBDayNight.isEvening?(timeNow)
        battle.time = 1
      else
        battle.time = 0
      end
    end
  end
end

class Game_Screen
  attr_reader   :field_effects
  alias initialize_field initialize
  def initialize
    initialize_field
    @field_effects = :None
  end
  def field_effect(type)
    @field_effects = GameData::FieldEffects.try_get(type).id
  end
end

class Battle::ActiveField
  attr_accessor :defaultField
  attr_accessor :field_effects
  alias initialize_field initialize
  def initialize
    initialize_field
    @effects[PBEffects::EchoChamber] = 0
    default_field_effects = :None
    field_effects = :None
  end
end

class Battle
  def pbCanUseItemOnPokemon?(item, pkmn, battler, scene, showMessages = true)
    if !pkmn || pkmn.egg?
      scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
      return false
    end
    if @opposes
      scene.pbDisplay(_INTL("Healing items cannot be used in battle."))
      return false
    end
    # Embargo
    if battler && battler.effects[PBEffects::Embargo] > 0
      if showMessages
        scene.pbDisplay(_INTL("Embargo's effect prevents the item's use on {1}!",
                              battler.pbThis(true)))
      end
      return false
    end
    # Hyper Mode and non-Scents
    if pkmn.hyper_mode && !GameData::Item.get(item)&.is_scent?
      scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
      return false
    end
    return true
  end
  def pbItemMenu(idxBattler, firstAction)
    if !@internalBattle || @opposes
      pbDisplay(_INTL("Items can't be used here."))
      return false
    end
    ret = false
    @scene.pbItemMenu(idxBattler, firstAction) { |item, useType, idxPkmn, idxMove, itemScene|
      next false if !item
      battler = pkmn = nil
      case useType
      when 1, 2   # Use on Pokémon/Pokémon's move
        next false if !ItemHandlers.hasBattleUseOnPokemon(item)
        battler = pbFindBattler(idxPkmn, idxBattler)
        pkmn    = pbParty(idxBattler)[idxPkmn]
        next false if !pbCanUseItemOnPokemon?(item, pkmn, battler, itemScene)
      when 3   # Use on battler
        next false if !ItemHandlers.hasBattleUseOnBattler(item)
        battler = pbFindBattler(idxPkmn, idxBattler)
        pkmn    = battler.pokemon if battler
        next false if !pbCanUseItemOnPokemon?(item, pkmn, battler, itemScene)
      when 4   # Poké Balls
        next false if idxPkmn < 0
        battler = @battlers[idxPkmn]
        pkmn    = battler.pokemon if battler
      when 5   # No target (Poké Doll, Guard Spec., Launcher items)
        battler = @battlers[idxBattler]
        pkmn    = battler.pokemon if battler
      else
        next false
      end
      next false if !pkmn
      next false if !ItemHandlers.triggerCanUseInBattle(item, pkmn, battler, idxMove,
                                                        firstAction, self, itemScene)
      next false if !pbRegisterItem(idxBattler, item, idxPkmn, idxMove)
      ret = true
      next true
    }
    return ret
  end
  def pbEORTerrainHealing(battler)
    return if battler.fainted?
    # Grassy Terrain (healing)
    if @field.terrain == :Grassy && battler.affectedByTerrain? && battler.canHeal?
      PBDebug.log("[Lingering effect] Grassy Terrain heals #{battler.pbThis(true)}")
      battler.pbRecoverHP(battler.totalhp / 16)
      pbDisplay(_INTL("{1}'s HP was restored.", battler.pbThis))
    end
    if @field.field_effects == :Ruins && battler.affectedByRuins? && battler.canHeal?
      PBDebug.log("[Lingering effect] Ruins field heals #{battler.pbThis(true)}")
      battler.pbRecoverHP(battler.totalhp / 16)
      pbDisplay(_INTL("{1}'s HP was restored by the power of the Ruins.", battler.pbThis))
    end
    if @field.field_effects == :Garden && battler.affectedByGarden? && battler.canHeal?
      PBDebug.log("[Lingering effect] Garden field heals #{battler.pbThis(true)}")
      battler.pbRecoverHP(battler.totalhp / 16)
      pbDisplay(_INTL("{1}'s HP was restored by the Garden.", battler.pbThis))
    end
    if @field.field_effects == :Swamp && battler.affectedBySwamp? && battler.canHeal? && battler.pbHasType?([:POISON,:WATER,:GRASS])
      PBDebug.log("[Lingering effect] Swamp field heals #{battler.pbThis(true)}")
      battler.pbRecoverHP(battler.totalhp / 16)
      pbDisplay(_INTL("{1}'s HP was restored by the Swamp.", battler.pbThis))
    end
  end
  def defaultField=(value)
    @field.defaultField  = value
    @field.field_effects         = value
  end
  def pbStartFieldEffect(user, newField)
    return if @field.field_effects == newField
    @field.field_effects = newField
    field_data = GameData::FieldEffects.try_get(@field.field_effects)
    pbHideAbilitySplash(user) if user
    case @field.field_effects
    when :EchoChamber
      pbDisplay(_INTL("A dull echo hums."))
    when :Desert
      pbDisplay(_INTL("Sand...it gets everywhere..."))
    when :Lava
      pbDisplay(_INTL("Hot lava flows around the battlefield."))
    when :ToxicFumes
      pbDisplay(_INTL("Poisonous gases fill the area."))
    when :Fire
      pbDisplay(_INTL("The field is ablaze."))
    when :Swamp
      pbDisplay(_INTL("The field is swampy."))
    when :City
      pbDisplay(_INTL("The city hums with activity."))
    when :Ruins
      pbDisplay(_INTL("There's an odd feeling in these ruins..."))
    when :Garden
      pbDisplay(_INTL("What a beautiful garden..."))
    end
    # Check for abilities/items that trigger upon the terrain changing
#    allBattlers.each { |b| b.pbAbilityOnTerrainChange }
#    allBattlers.each { |b| b.pbItemTerrainStatBoostCheck }
  end
  def pbStartWeather(user, newWeather, fixedDuration = false, showAnim = true)
    return if @field.weather == newWeather
    @field.weather = newWeather
    duration = (fixedDuration) ? 5 : -1
    if duration > 0 && user && user.itemActive?
      duration = Battle::ItemEffects.triggerWeatherExtender(user.item, @field.weather,
                                                            duration, user, self)
    end
    @field.weatherDuration = duration
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if showAnim && weather_data
    pbHideAbilitySplash(user) if user
    case @field.weather
    when :Sun         then pbDisplay(_INTL("The sunlight turned harsh!"))
    when :Rain        then pbDisplay(_INTL("It started to rain!"))
    when :Sandstorm   then pbDisplay(_INTL("A sandstorm brewed!"))
    when :Hail        then pbDisplay(_INTL("It started to hail!"))
    when :HarshSun    then pbDisplay(_INTL("The sunlight turned extremely harsh!"))
    when :HeavyRain   then pbDisplay(_INTL("A heavy rain began to fall!"))
    when :StrongWinds then pbDisplay(_INTL("Mysterious strong winds are protecting Flying-type Pokémon!"))
    when :ShadowSky   then pbDisplay(_INTL("A shadow sky appeared!"))
    when :AcidRain    then pbDisplay(_INTL("Acid rain began to fall!"))
    end

    case @field.field_effects
    when :Fire
      if @field.weather == :Rain || @field.weather == :HeavyRain
        @field.field_effects = :None
        pbDisplay(_INTL("The rain doused the wildfire!"))
        $field_effect_bg = "field"
        @scene.pbRefreshEverything
        if $cinders > 0
          pbDisplay(_INTL("The rain washed away the cinders!"))
          $cinders = 0
        end
      end
    when :City
      if @field.weather == :Rain
        @field.weather = :AcidRain
        pbDisplay(_INTL("The city smog corrupted the rain!"))
      end
    end
    # Check for end of primordial weather, and weather-triggered form changes
    allBattlers.each { |b| b.pbCheckFormOnWeatherChange }
    pbEndPrimordialWeather
  end
  def pbStartBattleCore
    # Set up the battlers on each side
    @field.field_effects = $game_screen.field_effects
    $field_effect_bg = nil
    $orig_water = false
    $orig_type_ice = false
    $orig_flying = false
    $cinders = 0
    $outage = false
    sendOuts = pbSetUpSides
    olditems = []
    pbParty(0).each_with_index do |pkmn,i|
      item = pkmn.item_id
      olditems.push(item)
    end
    $olditems = olditems
    # Create all the sprites and play the battle intro animation
    @scene.pbStartBattle(self)
    # Show trainers on both sides sending out Pokémon
    pbStartBattleSendOut(sendOuts)
    # Weather announcement
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if weather_data
    case @field.weather
    when :Sun         then pbDisplay(_INTL("The sunlight is strong."))
    when :Rain        then pbDisplay(_INTL("It is raining."))
    when :Sandstorm   then pbDisplay(_INTL("A sandstorm is raging."))
    when :Hail        then pbDisplay(_INTL("Hail is falling."))
    when :HarshSun    then pbDisplay(_INTL("The sunlight is extremely harsh."))
    when :HeavyRain   then pbDisplay(_INTL("It is raining heavily."))
    when :StrongWinds then pbDisplay(_INTL("The wind is strong."))
    when :ShadowSky   then pbDisplay(_INTL("The sky is shadowy."))
    when :AcidRain    then pbDisplay(_INTL("Acid rain is falling."))
    end
    # Terrain announcement
    terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
    pbCommonAnimation(terrain_data.animation) if terrain_data
    case @field.terrain
    when :Electric
      pbDisplay(_INTL("An electric current runs across the battlefield!"))
    when :Grassy
      pbDisplay(_INTL("Grass is covering the battlefield!"))
    when :Misty
      pbDisplay(_INTL("Mist swirls about the battlefield!"))
    when :Psychic
      pbDisplay(_INTL("The battlefield is weird!"))
    end
    case @field.field_effects
    when :EchoChamber
      pbDisplay(_INTL("A dull echo hums."))
    when :Desert
      pbDisplay(_INTL("Sand...it gets everywhere..."))
    when :Lava
      pbDisplay(_INTL("Hot lava flows around the battlefield."))
    when :ToxicFumes
      pbDisplay(_INTL("Poisonous gases fill the area."))
    when :Fire
      pbDisplay(_INTL("The field is ablaze."))
    when :Swamp
      pbDisplay(_INTL("The field is swampy."))
    when :City
      pbDisplay(_INTL("The city hums with activity."))
    when :Ruins
      pbDisplay(_INTL("There's an odd feeling in these ruins..."))
    when :Garden
      pbDisplay(_INTL("What a beautiful garden..."))
    end
    # Abilities upon entering battle
    pbOnAllBattlersEnteringBattle
    # Main battle loop
    pbBattleLoop
  end
  def pbEORField(battler)
    return if battler.fainted?
    amt = -1
    if $cinders > 0 && battler.affectedByCinders?
      pbDisplay(_INTL("{1} is hurt by the cinders!", battler.pbThis))
      amt = battler.totalhp / 16
      $cinders -= 1
    end
    case battler.effectiveField
    when :Lava
      return if !battler.takesLavaDamage?
      pbDisplay(_INTL("{1} is hurt by the lava!", battler.pbThis))
      amt = battler.totalhp / 16
    when :ToxicFumes
      return if !battler.affectedByFumes?
      fumes_rand = rand(100)
      if fumes_rand > 85
        pbDisplay(_INTL("{1} became confused by the toxic fumes!", battler.pbThis))
        battler.pbConfuse
      end
    end
    return if amt < 0
    @scene.pbDamageAnimation(battler)
    battler.pbReduceHP(amt, false)
    battler.pbItemHPHealCheck
    battler.pbFaint if battler.fainted?
  end
  def pbEORStatusProblemDamage(priority)
    #Damage from Frostbite
    priority.each do |b|
      next if b.status != :FROZEN || !b.takesIndirectDamage?
      oldHP = b.hp
      dmg = (Settings::MECHANICS_GENERATION >= 7) ? b.totalhp/16 : b.totalhp/8
      b.pbContinueStatus { b.pbReduceHP(dmg,false) }
      b.pbItemHPHealCheck
      b.pbAbilitiesOnDamageTaken(oldHP)
      b.pbFaint if b.fainted?
    end
    # Damage from poisoning
    priority.each do |battler|
      next if battler.fainted?
      next if battler.status != :POISON
      if battler.statusCount > 0
        battler.effects[PBEffects::Toxic] += 1
        battler.effects[PBEffects::Toxic] = 16 if battler.effects[PBEffects::Toxic] > 16
      end
      if battler.hasActiveAbility?(:POISONHEAL)
        if battler.canHeal?
          anim_name = GameData::Status.get(:POISON).animation
          pbCommonAnimation(anim_name, battler) if anim_name
          pbShowAbilitySplash(battler)
          battler.pbRecoverHP(battler.totalhp / 8)
          if Scene::USE_ABILITY_SPLASH
            pbDisplay(_INTL("{1}'s HP was restored.", battler.pbThis))
          else
            pbDisplay(_INTL("{1}'s {2} restored its HP.", battler.pbThis, battler.abilityName))
          end
          pbHideAbilitySplash(battler)
        end
      elsif battler.takesIndirectDamage?
        battler.droppedBelowHalfHP = false
        dmg = battler.totalhp / 8
        dmg = battler.totalhp * battler.effects[PBEffects::Toxic] / 16 if battler.statusCount > 0
        battler.pbContinueStatus { battler.pbReduceHP(dmg, false) }
        battler.pbItemHPHealCheck
        battler.pbAbilitiesOnDamageTaken
        battler.pbFaint if battler.fainted?
        battler.droppedBelowHalfHP = false
      end
    end
    # Damage from burn
    priority.each do |battler|
      next if battler.status != :BURN || !battler.takesIndirectDamage?
      battler.droppedBelowHalfHP = false
      dmg = (Settings::MECHANICS_GENERATION >= 7) ? battler.totalhp / 16 : battler.totalhp / 8
      dmg = (dmg / 2.0).round if battler.hasActiveAbility?(:HEATPROOF)
      battler.pbContinueStatus { battler.pbReduceHP(dmg, false) }
      battler.pbItemHPHealCheck
      battler.pbAbilitiesOnDamageTaken
      battler.pbFaint if battler.fainted?
      battler.droppedBelowHalfHP = false
    end
  end
  def pbEOREndWeather(priority)
    # NOTE: Primordial weather doesn't need to be checked here, because if it
    #       could wear off here, it will have worn off already.
    # Count down weather duration
    @field.weatherDuration -= 1 if @field.weatherDuration > 0
    # Weather wears off
    if @field.weatherDuration == 0
      case @field.weather
      when :Sun       then pbDisplay(_INTL("The sunlight faded."))
      when :Rain      then pbDisplay(_INTL("The rain stopped."))
      when :Sandstorm then pbDisplay(_INTL("The sandstorm subsided."))
      when :Hail      then pbDisplay(_INTL("The hail stopped."))
      when :ShadowSky then pbDisplay(_INTL("The shadow sky faded."))
      when :AcidRain  then pbDisplay(_INTL("The acid rain stopped."))
      end
      @field.weather = :None
      # Check for form changes caused by the weather changing
      allBattlers.each { |battler| battler.pbCheckFormOnWeatherChange }
      # Start up the default weather
      pbStartWeather(nil, @field.defaultWeather) if @field.defaultWeather != :None
      return if @field.weather == :None
    end
    # Weather continues
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if weather_data
    case @field.weather
#    when :Sun         then pbDisplay(_INTL("The sunlight is strong."))
#    when :Rain        then pbDisplay(_INTL("Rain continues to fall."))
    when :Sandstorm   then pbDisplay(_INTL("The sandstorm is raging."))
    when :Hail        then pbDisplay(_INTL("The hail is crashing down."))
#    when :HarshSun    then pbDisplay(_INTL("The sunlight is extremely harsh."))
#    when :HeavyRain   then pbDisplay(_INTL("It is raining heavily."))
#    when :StrongWinds then pbDisplay(_INTL("The wind is strong."))
    when :ShadowSky   then pbDisplay(_INTL("The shadow sky continues."))
    when :AcidRain    then pbDisplay(_INTL("The acid rain continues to fall."))
    end
    # Effects due to weather
    priority.each do |battler|
      # Weather-related abilities
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundWeather(battler.ability, battler.effectiveWeather, battler, self)
        battler.pbFaint if battler.fainted?
      end
      # Weather damage
      pbEORWeatherDamage(battler)
    end
  end
  def pbEORWeatherDamage(battler)
    return if battler.fainted?
    amt = -1
    case battler.effectiveWeather
    when :Sandstorm
      return if !battler.takesSandstormDamage?
      pbDisplay(_INTL("{1} is buffeted by the sandstorm!", battler.pbThis))
      amt = battler.totalhp / 16
    when :AcidRain
      return if !battler.takesAcidRainDamage?
      pbDisplay(_INTL("{1} is scathed by the acid rain!", battler.pbThis))
      amt = battler.totalhp / 16
    when :Hail
      return if !battler.takesHailDamage?
      pbDisplay(_INTL("{1} is buffeted by the hail!", battler.pbThis))
      amt = battler.totalhp / 16
    when :ShadowSky
      return if !battler.takesShadowSkyDamage?
      pbDisplay(_INTL("{1} is hurt by the shadow sky!", battler.pbThis))
      amt = battler.totalhp / 16
    end
    return if amt < 0
    @scene.pbDamageAnimation(battler)
    battler.pbReduceHP(amt, false)
    battler.pbItemHPHealCheck
    battler.pbFaint if battler.fainted?
  end
  def pbEndOfRoundPhase
    PBDebug.log("")
    PBDebug.log("[End of round]")
    @endOfRound = true
    @scene.pbBeginEndOfRoundPhase
    pbCalculatePriority           # recalculate speeds
    priority = pbPriority(true)   # in order of fastest -> slowest speeds only
    # Weather
    pbEOREndWeather(priority)
    # Future Sight/Doom Desire
    @positions.each_with_index { |pos, idxPos| pbEORUseFutureSight(pos, idxPos) }
    # Wish
    pbEORWishHealing
    # Sea of Fire damage (Fire Pledge + Grass Pledge combination)
    pbEORSeaOfFireDamage(priority)
    # Status-curing effects/abilities and HP-healing items
    priority.each do |battler|
      #Field Effects
      pbEORField(battler)
      #Terrain Healing
      pbEORTerrainHealing(battler)
      # Healer, Hydration, Shed Skin
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundHealing(battler.ability, battler, self)
      end
      # Black Sludge, Leftovers
      if battler.itemActive?
        Battle::ItemEffects.triggerEndOfRoundHealing(battler.item, battler, self)
      end
    end
    # Self-curing of status due to affection
    if Settings::AFFECTION_EFFECTS && @internalBattle
      priority.each do |battler|
        next if battler.fainted? || battler.status == :NONE
        next if !battler.pbOwnedByPlayer? || battler.affection_level < 4 || battler.mega?
        next if pbRandom(100) < 80
        old_status = battler.status
        battler.pbCureStatus(false)
        case old_status
        when :SLEEP
          pbDisplay(_INTL("{1} shook itself awake so you wouldn't worry!", battler.pbThis))
        when :POISON
          pbDisplay(_INTL("{1} managed to expel the poison so you wouldn't worry!", battler.pbThis))
        when :BURN
          pbDisplay(_INTL("{1} healed its burn with its sheer determination so you wouldn't worry!", battler.pbThis))
        when :PARALYSIS
          pbDisplay(_INTL("{1} gathered all its energy to break through its paralysis so you wouldn't worry!", battler.pbThis))
        when :FROZEN
          pbDisplay(_INTL("{1} melted the ice with its fiery determination so you wouldn't worry!", battler.pbThis))
        end
      end
    end
    # Healing from Aqua Ring, Ingrain, Leech Seed
    pbEORHealingEffects(priority)
    # Damage from Hyper Mode (Shadow Pokémon)
    priority.each do |battler|
      next if !battler.inHyperMode? || @choices[battler.index][0] != :UseMove
      hpLoss = battler.totalhp / 24
      @scene.pbDamageAnimation(battler)
      battler.pbReduceHP(hpLoss, false)
      pbDisplay(_INTL("The Hyper Mode attack hurts {1}!", battler.pbThis(true)))
      battler.pbFaint if battler.fainted?
    end
    # Damage from poison/burn
    pbEORStatusProblemDamage(priority)
    # Damage from Nightmare and Curse
    pbEOREffectDamage(priority)
    # Trapping attacks (Bind/Clamp/Fire Spin/Magma Storm/Sand Tomb/Whirlpool/Wrap)
    priority.each { |battler| pbEORTrappingDamage(battler) }
    # Octolock
    priority.each do |battler|
      next if battler.fainted? || battler.effects[PBEffects::Octolock] < 0
      pbCommonAnimation("Octolock", battler)
      battler.pbLowerStatStage(:DEFENSE, 1, nil) if battler.pbCanLowerStatStage?(:DEFENSE)
      battler.pbLowerStatStage(:SPECIAL_DEFENSE, 1, nil) if battler.pbCanLowerStatStage?(:SPECIAL_DEFENSE)
      battler.pbItemOnStatDropped
    end
    # Effects that apply to a battler that wear off after a number of rounds
    pbEOREndBattlerEffects(priority)
    # Check for end of battle (i.e. because of Perish Song)
    if @decision > 0
      pbGainExp
      return
    end
    # Effects that apply to a side that wear off after a number of rounds
    2.times { |side| pbEOREndSideEffects(side, priority) }
    # Effects that apply to the whole field that wear off after a number of rounds
    pbEOREndFieldEffects(priority)
    # End of terrains
    pbEOREndTerrain
    priority.each do |battler|
      # Self-inflicted effects that wear off after a number of rounds
      pbEOREndBattlerSelfEffects(battler)
      # Bad Dreams, Moody, Speed Boost
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundEffect(battler.ability, battler, self)
      end
      # Flame Orb, Sticky Barb, Toxic Orb
      if battler.itemActive?
        Battle::ItemEffects.triggerEndOfRoundEffect(battler.item, battler, self)
      end
      # Harvest, Pickup, Ball Fetch
      if battler.abilityActive?
        Battle::AbilityEffects.triggerEndOfRoundGainItem(battler.ability, battler, self)
      end
    end
    pbGainExp
    return if @decision > 0
    # Form checks
    priority.each { |battler| battler.pbCheckForm(true) }
    # Switch Pokémon in if possible
    pbEORSwitch
    return if @decision > 0
    # In battles with at least one side of size 3+, move battlers around if none
    # are near to any foes
    pbEORShiftDistantBattlers
    # Try to make Trace work, check for end of primordial weather
    priority.each { |battler| battler.pbContinualAbilityChecks }
    # Reset/count down battler-specific effects (no messages)
    allBattlers.each do |battler|
      battler.effects[PBEffects::BanefulBunker]    = false
      battler.effects[PBEffects::Charge]           -= 1 if battler.effects[PBEffects::Charge] > 0
      battler.effects[PBEffects::Counter]          = -1
      battler.effects[PBEffects::CounterTarget]    = -1
      battler.effects[PBEffects::Electrify]        = false
      battler.effects[PBEffects::Endure]           = false
      battler.effects[PBEffects::FirstPledge]      = nil
      battler.effects[PBEffects::Flinch]           = false
      battler.effects[PBEffects::FocusPunch]       = false
      battler.effects[PBEffects::FollowMe]         = 0
      battler.effects[PBEffects::HelpingHand]      = false
      battler.effects[PBEffects::HyperBeam]        -= 1 if battler.effects[PBEffects::HyperBeam] > 0
      battler.effects[PBEffects::KingsShield]      = false
      battler.effects[PBEffects::LaserFocus]       -= 1 if battler.effects[PBEffects::LaserFocus] > 0
      if battler.effects[PBEffects::LockOn] > 0   # Also Mind Reader
        battler.effects[PBEffects::LockOn]         -= 1
        battler.effects[PBEffects::LockOnPos]      = -1 if battler.effects[PBEffects::LockOn] == 0
      end
      battler.effects[PBEffects::MagicBounce]      = false
      battler.effects[PBEffects::MagicCoat]        = false
      battler.effects[PBEffects::MirrorCoat]       = -1
      battler.effects[PBEffects::MirrorCoatTarget] = -1
      battler.effects[PBEffects::Obstruct]         = false
      battler.effects[PBEffects::Powder]           = false
      battler.effects[PBEffects::Prankster]        = false
      battler.effects[PBEffects::PriorityAbility]  = false
      battler.effects[PBEffects::PriorityItem]     = false
      battler.effects[PBEffects::Protect]          = false
      battler.effects[PBEffects::RagePowder]       = false
      battler.effects[PBEffects::CaennerbongDance] = false
      if battler.effects[PBEffects::Singed] == 1
        battler.effects[PBEffects::Roost]            = true
      else
        battler.effects[PBEffects::Roost]            = false
      end
      battler.effects[PBEffects::Snatch]           = 0
      battler.effects[PBEffects::SpikyShield]      = false
      battler.effects[PBEffects::Spotlight]        = 0
      battler.effects[PBEffects::ThroatChop]       -= 1 if battler.effects[PBEffects::ThroatChop] > 0
      battler.lastHPLost                           = 0
      battler.lastHPLostFromFoe                    = 0
      battler.droppedBelowHalfHP                   = false
      battler.statsDropped                         = false
      battler.tookDamageThisRound                  = false
      battler.tookPhysicalHit                      = false
      battler.statsRaisedThisRound                 = false
      battler.statsLoweredThisRound                = false
      battler.canRestoreIceFace                    = false
      battler.lastRoundMoveFailed                  = battler.lastMoveFailed
      battler.lastAttacker.clear
      battler.lastFoeAttacker.clear
    end
    # Reset/count down side-specific effects (no messages)
    2.times do |side|
      @sides[side].effects[PBEffects::CraftyShield]         = false
      if !@sides[side].effects[PBEffects::EchoedVoiceUsed]
        @sides[side].effects[PBEffects::EchoedVoiceCounter] = 0
      end
      @sides[side].effects[PBEffects::EchoedVoiceUsed]      = false
      @sides[side].effects[PBEffects::MatBlock]             = false
      @sides[side].effects[PBEffects::QuickGuard]           = false
      @sides[side].effects[PBEffects::Round]                = false
      @sides[side].effects[PBEffects::WideGuard]            = false
    end
    # Reset/count down field-specific effects (no messages)
    @field.effects[PBEffects::IonDeluge]   = false
    @field.effects[PBEffects::FairyLock]   -= 1 if @field.effects[PBEffects::FairyLock] > 0
    @field.effects[PBEffects::FusionBolt]  = false
    @field.effects[PBEffects::FusionFlare] = false
    @endOfRound = false
  end
  def pbEndOfBattle
    oldDecision = @decision
    @decision = 4 if @decision == 1 && wildBattle? && @caughtPokemon.length > 0
    case oldDecision
    ##### WIN #####
    when 1
      PBDebug.log("")
      PBDebug.log("***Player won***")
      if trainerBattle?
        @scene.pbTrainerBattleSuccess
        case @opponent.length
        when 1
          pbDisplayPaused(_INTL("You defeated {1}!", @opponent[0].full_name))
        when 2
          pbDisplayPaused(_INTL("You defeated {1} and {2}!", @opponent[0].full_name,
                                @opponent[1].full_name))
        when 3
          pbDisplayPaused(_INTL("You defeated {1}, {2} and {3}!", @opponent[0].full_name,
                                @opponent[1].full_name, @opponent[2].full_name))
        end
        @opponent.each_with_index do |trainer, i|
          @scene.pbShowOpponent(i)
          msg = trainer.lose_text
          msg = "..." if !msg || msg.empty?
          pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/, pbPlayer.name))
        end
      end
      if wildBattle?
        $map_log.register($game_map.map_id)
      end
      # Gain money from winning a trainer battle, and from Pay Day
      pbGainMoney if @decision != 4
      # Hide remaining trainer
      @scene.pbShowOpponent(@opponent.length) if trainerBattle? && @caughtPokemon.length > 0
    ##### LOSE, DRAW #####
    when 2, 5
      PBDebug.log("")
      PBDebug.log("***Player lost***") if @decision == 2
      PBDebug.log("***Player drew with opponent***") if @decision == 5
      if @internalBattle
        pbDisplayPaused(_INTL("You have no more Pokémon that can fight!"))
        if trainerBattle?
          case @opponent.length
          when 1
            pbDisplayPaused(_INTL("You lost against {1}!", @opponent[0].full_name))
          when 2
            pbDisplayPaused(_INTL("You lost against {1} and {2}!",
                                  @opponent[0].full_name, @opponent[1].full_name))
          when 3
            pbDisplayPaused(_INTL("You lost against {1}, {2} and {3}!",
                                  @opponent[0].full_name, @opponent[1].full_name, @opponent[2].full_name))
          end
        end
        # Lose money from losing a battle
        pbLoseMoney
        pbDisplayPaused(_INTL("You blacked out!")) if !@canLose
      elsif @decision == 2   # Lost in a Battle Frontier battle
        if @opponent
          @opponent.each_with_index do |trainer, i|
            @scene.pbShowOpponent(i)
            msg = trainer.win_text
            msg = "..." if !msg || msg.empty?
            pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/, pbPlayer.name))
          end
        end
      end
    ##### CAUGHT WILD POKÉMON #####
    when 4
      $map_log.register($game_map.map_id)
      @scene.pbWildBattleSuccess if !Settings::GAIN_EXP_FOR_CAPTURE
    end
    # Register captured Pokémon in the Pokédex, and store them
    pbRecordAndStoreCaughtPokemon
    # Collect Pay Day money in a wild battle that ended in a capture
    pbGainMoney if @decision == 4
    # Pass on Pokérus within the party
    if @internalBattle
      infected = []
      $player.party.each_with_index do |pkmn, i|
        infected.push(i) if pkmn.pokerusStage == 1
      end
      infected.each do |idxParty|
        strain = $player.party[idxParty].pokerusStrain
        if idxParty > 0 && $player.party[idxParty - 1].pokerusStage == 0 && rand(3) == 0   # 33%
          $player.party[idxParty - 1].givePokerus(strain)
        end
        if idxParty < $player.party.length - 1 && $player.party[idxParty + 1].pokerusStage == 0 && rand(3) == 0   # 33%
          $player.party[idxParty + 1].givePokerus(strain)
        end
      end
    end
    # Clean up battle stuff
    @scene.pbEndBattle(@decision)
    @battlers.each do |b|
      next if !b
      pbCancelChoice(b.index)   # Restore unused items to Bag
      Battle::AbilityEffects.triggerOnSwitchOut(b.ability, b, true) if b.abilityActive?
    end
    pbParty(0).each_with_index do |pkmn,i|
      next if !pkmn
      @peer.pbOnLeavingBattle(self,pkmn,@usedInBattle[0][i],true)   # Reset form
      $bag.add($olditems[i])
      pkmn.item = nil
      $player.party.delete_at(i) if pkmn.fainted?
    end
    return @decision
  end
end

#Echo Chamber
class Battle::Move
  def pbChangeUsageCounters(user,specialUsage)
    user.effects[PBEffects::FuryCutter]   = 0
    user.effects[PBEffects::ParentalBond] = 0
    user.effects[PBEffects::ProtectRate]  = 1
    user.effects[PBEffects::EchoChamber] = 0
    @battle.field.effects[PBEffects::FusionBolt]  = false
    @battle.field.effects[PBEffects::FusionFlare] = false
  end

  def pbBeamMove?;            return beamMove?; end
  def pbSoundMove?;           return soundMove?; end

  def pbNumHits(user,targets)
    if user.hasActiveAbility?(:PARENTALBOND) && pbDamagingMove? &&
       !chargingTurnMove? && targets.length==1
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::ParentalBond] = 3
      return 2
    end
    if pbSoundMove? && battle.field.field_effects == :EchoChamber &&
       !chargingTurnMove? && targets.length==1 && pbDamagingMove?
      # Record that Parental Bond applies, to weaken the second attack
      user.effects[PBEffects::EchoChamber] = 3
      return 2
    end
    return 1
  end
end

class Battle::Battler
  def pbProcessMoveHit(move, user, targets, hitNum, skipAccuracyCheck)
    return false if user.fainted?
    # For two-turn attacks being used in a single turn
    move.pbInitialEffect(user, targets, hitNum)
    numTargets = 0   # Number of targets that are affected by this hit
    # Count a hit for Parental Bond (if it applies)
    user.effects[PBEffects::ParentalBond] -= 1 if user.effects[PBEffects::ParentalBond] > 0
    user.effects[PBEffects::EchoChamber] -= 1 if user.effects[PBEffects::EchoChamber] > 0
    # Accuracy check (accuracy/evasion calc)
    if hitNum == 0 || move.successCheckPerHit?
      targets.each do |b|
        b.damageState.missed = false
        next if b.damageState.unaffected
        if pbSuccessCheckPerHit(move, user, b, skipAccuracyCheck)
          numTargets += 1
        else
          b.damageState.missed     = true
          b.damageState.unaffected = true
        end
      end
      # If failed against all targets
      if targets.length > 0 && numTargets == 0 && !move.worksWithNoTargets?
        targets.each do |b|
          next if !b.damageState.missed || b.damageState.magicCoat
          pbMissMessage(move, user, b)
          if user.itemActive?
            Battle::ItemEffects.triggerOnMissingTarget(user.item, user, b, move, hitNum, @battle)
          end
          break if move.pbRepeatHit?   # Dragon Darts only shows one failure message
        end
        move.pbCrashDamage(user)
        user.pbItemHPHealCheck
        pbCancelMoves
        return false
      end
    end
    # If we get here, this hit will happen and do something
    all_targets = targets
    targets = move.pbDesignateTargetsForHit(targets, hitNum)   # For Dragon Darts
    targets.each { |b| b.damageState.resetPerHit }
    #---------------------------------------------------------------------------
    # Calculate damage to deal
    if move.pbDamagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        # Check whether Substitute/Disguise will absorb the damage
        move.pbCheckDamageAbsorption(user, b)
        # Calculate the damage against b
        # pbCalcDamage shows the "eat berry" animation for SE-weakening
        # berries, although the message about it comes after the additional
        # effect below
        move.pbCalcDamage(user, b, targets.length)   # Stored in damageState.calcDamage
        # Lessen damage dealt because of False Swipe/Endure/etc.
        move.pbReduceDamage(user, b)   # Stored in damageState.hpLost
      end
    end
    # Show move animation (for this hit)
    move.pbShowAnimation(move.id, user, targets, hitNum)
    # Type-boosting Gem consume animation/message
    if user.effects[PBEffects::GemConsumed] && hitNum == 0
      # NOTE: The consume animation and message for Gems are shown now, but the
      #       actual removal of the item happens in def pbEffectsAfterMove.
      @battle.pbCommonAnimation("UseItem", user)
      @battle.pbDisplay(_INTL("The {1} strengthened {2}'s power!",
                              GameData::Item.get(user.effects[PBEffects::GemConsumed]).name, move.name))
    end
    # Messages about missed target(s) (relevant for multi-target moves only)
    if !move.pbRepeatHit?
      targets.each do |b|
        next if !b.damageState.missed
        pbMissMessage(move, user, b)
        if user.itemActive?
          Battle::ItemEffects.triggerOnMissingTarget(user.item, user, b, move, hitNum, @battle)
        end
      end
    end
    # Deal the damage (to all allies first simultaneously, then all foes
    # simultaneously)
    if move.pbDamagingMove?
      # This just changes the HP amounts and does nothing else
      targets.each { |b| move.pbInflictHPDamage(b) if !b.damageState.unaffected }
      # Animate the hit flashing and HP bar changes
      move.pbAnimateHitAndHPLost(user, targets)
    end
    # Self-Destruct/Explosion's damaging and fainting of user
    move.pbSelfKO(user) if hitNum == 0
    user.pbFaint if user.fainted?
    if move.pbDamagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        # NOTE: This method is also used for the OHKO special message.
        move.pbHitEffectivenessMessages(user, b, targets.length)
        # Record data about the hit for various effects' purposes
        move.pbRecordDamageLost(user, b)
      end
      # Close Combat/Superpower's stat-lowering, Flame Burst's splash damage,
      # and Incinerate's berry destruction
      targets.each do |b|
        next if b.damageState.unaffected
        move.pbEffectWhenDealingDamage(user, b)
      end
      # Ability/item effects such as Static/Rocky Helmet, and Grudge, etc.
      targets.each do |b|
        next if b.damageState.unaffected
        pbEffectsOnMakingHit(move, user, b)
      end
      # Disguise/Endure/Sturdy/Focus Sash/Focus Band messages
      targets.each do |b|
        next if b.damageState.unaffected
        move.pbEndureKOMessage(b)
      end
      # HP-healing held items (checks all battlers rather than just targets
      # because Flame Burst's splash damage affects non-targets)
      @battle.pbPriority(true).each { |b| b.pbItemHPHealCheck }
      # Animate battlers fainting (checks all battlers rather than just targets
      # because Flame Burst's splash damage affects non-targets)
      @battle.pbPriority(true).each { |b| b.pbFaint if b&.fainted? }
    end
    @battle.pbJudgeCheckpoint(user, move)
    # Main effect (recoil/drain, etc.)
    targets.each do |b|
      next if b.damageState.unaffected
      move.pbEffectAgainstTarget(user, b)
    end
    move.pbEffectGeneral(user)
    targets.each { |b| b.pbFaint if b&.fainted? }
    user.pbFaint if user.fainted?
    # Additional effect
    if !user.hasActiveAbility?(:SHEERFORCE)
      targets.each do |b|
        next if b.damageState.calcDamage == 0
        chance = move.pbAdditionalEffectChance(user, b)
        next if chance <= 0
        if @battle.pbRandom(100) < chance
          move.pbAdditionalEffect(user, b)
        end
      end
    end
    # Make the target flinch (because of an item/ability)
    targets.each do |b|
      next if b.fainted?
      next if b.damageState.calcDamage == 0 || b.damageState.substitute
      chance = move.pbFlinchChance(user, b)
      next if chance <= 0
      if @battle.pbRandom(100) < chance
        PBDebug.log("[Item/ability triggered] #{user.pbThis}'s King's Rock/Razor Fang or Stench")
        b.pbFlinch(user)
      end
    end
    # Message for and consuming of type-weakening berries
    # NOTE: The "consume held item" animation for type-weakening berries occurs
    #       during pbCalcDamage above (before the move's animation), but the
    #       message about it only shows here.
    targets.each do |b|
      next if b.damageState.unaffected
      next if !b.damageState.berryWeakened
      @battle.pbDisplay(_INTL("The {1} weakened the damage to {2}!", b.itemName, b.pbThis(true)))
      b.pbConsumeItem
    end
    # Steam Engine (goes here because it should be after stat changes caused by
    # the move)
    if [:FIRE, :WATER].include?(move.calcType)
      targets.each do |b|
        next if b.damageState.unaffected
        next if b.damageState.calcDamage == 0 || b.damageState.substitute
        next if !b.hasActiveAbility?(:STEAMENGINE)
        b.pbRaiseStatStageByAbility(:SPEED, 6, b) if b.pbCanRaiseStatStage?(:SPEED, b)
      end
    end
    # Fainting
    targets.each { |b| b.pbFaint if b&.fainted? }
    user.pbFaint if user.fainted?
    # Dragon Darts' second half of attack
    if move.pbRepeatHit? && hitNum == 0 &&
       targets.any? { |b| !b.fainted? && !b.damageState.unaffected }
      pbProcessMoveHit(move, user, all_targets, 1, skipAccuracyCheck)
    end
    return true
  end
end

#Field Changes due to Move Usage
class Battle::Scene
  def pbFindMoveAnimation(moveID, idxUser, hitNum)
    begin
      move2anim = pbLoadMoveToAnim
      # Find actual animation requested (an opponent using the animation first
      # looks for an OppMove version then a Move version)
      anim = pbFindMoveAnimDetails(move2anim, moveID, idxUser, hitNum)
      return anim if anim
      # Actual animation not found, get the default animation for the move's type
      moveData = GameData::Move.get(moveID)
      target_data = GameData::Target.get(moveData.target)
      moveType = moveData.type
      moveKind = moveData.category
      moveKind += 3 if target_data.num_targets > 1 || target_data.affects_foe_side
      moveKind += 3 if moveKind == 2 && target_data.num_targets > 0
      # [one target physical, one target special, user status,
      #  multiple targets physical, multiple targets special, non-user status]
      typeDefaultAnim = {
        :NORMAL   => [:TACKLE,       :SONICBOOM,    :DEFENSECURL, :EXPLOSION,  :SWIFT,        :TAILWHIP],
        :FIGHTING => [:MACHPUNCH,    :AURASPHERE,   :DETECT,      nil,         nil,           nil],
        :FLYING   => [:WINGATTACK,   :GUST,         :ROOST,       nil,         :AIRCUTTER,    :FEATHERDANCE],
        :POISON   => [:POISONSTING,  :SLUDGE,       :ACIDARMOR,   nil,         :ACID,         :POISONPOWDER],
        :GROUND   => [:SANDTOMB,     :MUDSLAP,      nil,          :EARTHQUAKE, :EARTHPOWER,   :MUDSPORT],
        :ROCK     => [:ROCKTHROW,    :POWERGEM,     :ROCKPOLISH,  :ROCKSLIDE,  nil,           :SANDSTORM],
        :BUG      => [:TWINEEDLE,    :BUGBUZZ,      :QUIVERDANCE, nil,         :STRUGGLEBUG,  :STRINGSHOT],
        :GHOST    => [:LICK,         :SHADOWBALL,   :GRUDGE,      nil,         nil,           :CONFUSERAY],
        :STEEL    => [:IRONHEAD,     :MIRRORSHOT,   :IRONDEFENSE, nil,         nil,           :METALSOUND],
        :FIRE     => [:FIREPUNCH,    :EMBER,        :SUNNYDAY,    nil,         :INCINERATE,   :WILLOWISP],
        :WATER    => [:CRABHAMMER,   :WATERGUN,     :AQUARING,    nil,         :SURF,         :WATERSPORT],
        :GRASS    => [:VINEWHIP,     :MEGADRAIN,    :COTTONGUARD, :RAZORLEAF,  nil,           :SPORE],
        :ELECTRIC => [:THUNDERPUNCH, :THUNDERSHOCK, :CHARGE,      nil,         :DISCHARGE,    :THUNDERWAVE],
        :PSYCHIC  => [:ZENHEADBUTT,  :CONFUSION,    :CALMMIND,    nil,         :SYNCHRONOISE, :MIRACLEEYE],
        :ICE      => [:ICEPUNCH,     :ICEBEAM,      :MIST,        nil,         :POWDERSNOW,   :HAIL],
        :DRAGON   => [:DRAGONCLAW,   :DRAGONRAGE,   :DRAGONDANCE, nil,         :TWISTER,      nil],
        :DARK     => [:PURSUIT,      :DARKPULSE,    :HONECLAWS,   nil,         :SNARL,        :EMBARGO],
        :FAIRY    => [:TACKLE,       :FAIRYWIND,    :MOONLIGHT,   nil,         :SWIFT,        :SWEETKISS]
      }
      if typeDefaultAnim[moveType]
        anims = typeDefaultAnim[moveType]
        if GameData::Move.exists?(anims[moveKind])
          anim = pbFindMoveAnimDetails(move2anim, anims[moveKind], idxUser)
        end
        if !anim && moveKind >= 3 && GameData::Move.exists?(anims[moveKind - 3])
          anim = pbFindMoveAnimDetails(move2anim, anims[moveKind - 3], idxUser)
        end
        if !anim && GameData::Move.exists?(anims[2])
          anim = pbFindMoveAnimDetails(move2anim, anims[2], idxUser)
        end
      end
      return anim if anim
      # Default animation for the move's type not found, use Tackle's animation
      if GameData::Move.exists?(:TACKLE)
        return pbFindMoveAnimDetails(move2anim, :TACKLE, idxUser)
      end
    rescue
    end
    return nil
  end
  def pbCreateBackdropSprites
    case @battle.time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    # Put everything together into backdrop, bases and message bar filenames
    @battle.backdrop = $field_effect_bg if $field_effect_bg != nil
    @battle.backdropBase = $field_effect_bg if $field_effect_bg != nil
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    messageFilename = @battle.backdrop
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_bg"))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base0"))
        baseFilename = trialName
      end
      trialName = sprintf("%s_%s", messageFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_message"))
        messageFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/" + baseFilename + "_base0")) &&
       @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base0"))
          baseFilename = trialName
        end
      end
    end
    # Finalise filenames
    battleBG   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    playerBase = "Graphics/Battlebacks/" + baseFilename + "_base0"
    enemyBase  = "Graphics/Battlebacks/" + baseFilename + "_base1"
    messageBG  = "Graphics/Battlebacks/" + messageFilename + "_message"
    # Apply graphics
    bg = pbAddSprite("battle_bg", 0, 0, battleBG, @viewport)
    bg.z = 0
    bg = pbAddSprite("battle_bg2", -Graphics.width, 0, battleBG, @viewport)
    bg.z      = 0
    bg.mirror = true
    2.times do |side|
      baseX, baseY = Battle::Scene.pbBattlerPosition(side)
      base = pbAddSprite("base_#{side}", baseX, baseY,
                         (side == 0) ? playerBase : enemyBase, @viewport)
      base.z = 1
      if base.bitmap
        base.ox = base.bitmap.width / 2
        base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
      end
    end
    cmdBarBG = pbAddSprite("cmdBar_bg", 0, Graphics.height - 96, messageBG, @viewport)
    cmdBarBG.z = 180
  end
end

class Battle
  def type_effects(battler)
    type1 = battler.types[0]
    case type1
    when :NORMAL
      $neutral = true
    when :FIGHTING
      battler.eachOpposing.do {|target|
        target.stages[:DEFENSE] -= 1
        target.stages[:SPECIAL_DEFENSE] -= 1
      }
    when :FLYING
      battler.stages[:EVASION] += 2
    when :POISON
      battler.eachOpposing.do {|target|
        tox = rand(100)
        target.status = :POISON if tox < 20
      }
    when :ROCK
      $rock = true
    when :STEEL
      $rock = true
    when :GROUND
      battler.eachOpposing.do {|target|
        target.stages[:ACCURACY] -= 1
      }
    when :BUG
      statuses = [:SLEEP,:POISON,:PARALYSIS,:FROZEN,:BURN]
      battler.eachOpposing.do {|target|
        stt = rand(100)
        st = rand(statuses.length)
        battler.status = statuses[st] if stt < 20
      }
    when :GHOST
      battler.eachOpposing.do {|target|
        curse = rand(100)
        target.effects[PBEffects::Curse] = true if curse < 10
      }
    when :GRASS
      battler.eachOpposing.do {|target|
        slp = rand(100)
        target.status = :SLEEP if slp < 20
      }
    when :FIRE
      battler.eachOpposing.do {|target|
        brn = rand(100)
        target.status = :BURN if brn < 20
      }
    when :WATER
      battler.eachOpposing.do {|target|
        target.stages[:SPEED] -= 1
      }
    when :ELECTRIC
      battler.eachOpposing.do {|target|
        prz = rand(100)
        target.status = :PARALYSIS if prz < 20
      }
    when :ICE
      battler.eachOpposing.do {|target|
        frz = rand(100)
        target.status = :FROZEN if frz < 20
      }
    when :PSYCHIC
      battler.eachOpposing.do {|target|
        cnf = rand(100)
        target.pbConfuse if cnf < 20
      }
    when :DRAGON
      battler.eachOpposing.do {|target|
        target.stages[:ATTACK] -= 1
      }
    when :DARK
      battler.eachOpposing.do {|target|
        target.stages[:SPECIAL_ATTACK] -= 1
      }
    when :FAIRY
      battler.eachOpposing.do {|target|
        atr = rand(100)
        target.pbAttract(battler) if atr < 20
      }
    end
  end
end