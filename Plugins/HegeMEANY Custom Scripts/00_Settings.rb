module Settings
  #UPDATE THIS WITH EVERY PUSH!!!!!!!!!!!!!!
  GAME_VERSION = "1.0.0"
  TIME_SHADING = false
  GAIN_EXP_FOR_CAPTURE                 = false
end

Essentials::ERROR_TEXT += "[Pokémon HegeMEANY v#{Settings::GAME_VERSION}]\r\n"

class MapLog  
  attr_reader :list

  def initialize
    @list = []
  end

  def setup
    @list = $game_variables[99]
  end

  def register(mapid)
    @list.push(mapid)
    $game_variables[99] = @list
  end

  def registered?(mapid)
    return false if @list.nil?
    return true if @list.include?(mapid)
    return false
  end
end

module Game
  def self.start_new
    if $game_map&.events
      $game_map.events.each_value { |event| event.clear_starting }
    end
    $game_temp.common_event_id = 0 if $game_temp
    $game_temp.begun_new_game = true
    $scene = Scene_Map.new
    SaveData.load_new_game_values
    $stats.play_sessions += 1
    $close_dexnav = 0

    $map_log = MapLog.new
    $map_factory = PokemonMapFactory.new($data_system.start_map_id)
    $game_player.moveto($data_system.start_x, $data_system.start_y)
    $game_player.refresh
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    $game_map.autoplay
    $game_map.update
  end
  def self.load(save_data)
    validate save_data => Hash
    SaveData.load_all_values(save_data)
    $stats.play_sessions += 1
    self.load_map
    pbAutoplayOnSave
    $map_log = MapLog.new
    $map_log.setup
    $game_map.update
    $PokemonMap.updateMap
    $scene = Scene_Map.new
  end
end

def write_version
  File.open("version.txt", "wb") { |f|
    version = Settings::GAME_VERSION
    f.write("#{version}")
  }
end


def write_money
  File.open("money.txt", "wb") { |f|
    money = $game_variables[72]
    run = read_run
    if run > 4
      moneyadd = 25000 * (run-4)
    else
      moneyadd = 0
    end
    mon = money + moneyadd
    f.write("#{mon}")
  }
end

def write_run
  File.open("run.txt", "wb") { |f|
    floor = [80,82,83,84,85,86,87,88]
    for i in floor
      idx += 1
      break if $game_map.map_id == i
    end
    idx = 7 if idx > 7
    run = idx
    f.write("#{run}")
  }
end

def read_money
  File.open("money.txt", "rb") { |f|
    money = f.read
    money = money.to_i
  return money
  }
end

def read_run
  File.open("run.txt", "rb") { |f|
    run = f.read
    run = run.to_i
  return run
  }
end

def pbStartOver(gameover = true)
  if pbInBugContest?
    pbBugContestStartOver
    return
  end
  if gameover
    pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]Better luck next time..."))
    write_run
    write_money
    SaveData.delete_file
    raise SystemExit.new
  end
  $stats.blacked_out_count += 1
  $player.heal_party
  if $PokemonGlobal.pokecenterMapId && $PokemonGlobal.pokecenterMapId >= 0
    if gameover
      pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]After the unfortunate defeat, you scurry back to a Pokémon Center."))
    else
      pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]You scurry back to a Pokémon Center, protecting your exhausted Pokémon from any further harm..."))
    end
    pbCancelVehicles
    Followers.clear
    $game_switches[Settings::STARTING_OVER_SWITCH] = true
    $game_temp.player_new_map_id    = $PokemonGlobal.pokecenterMapId
    $game_temp.player_new_x         = $PokemonGlobal.pokecenterX
    $game_temp.player_new_y         = $PokemonGlobal.pokecenterY
    $game_temp.player_new_direction = $PokemonGlobal.pokecenterDirection
    $scene.transfer_player if $scene.is_a?(Scene_Map)
    $game_map.refresh
  else
    homedata = GameData::PlayerMetadata.get($player.character_ID)&.home
    homedata = GameData::Metadata.get.home if !homedata
    if homedata && !pbRgssExists?(sprintf("Data/Map%03d.rxdata", homedata[0]))
      if $DEBUG
        pbMessage(_ISPRINTF("Can't find the map 'Map{1:03d}' in the Data folder. The game will resume at the player's position.", homedata[0]))
      end
      $player.heal_party
      return
    end
    if gameover
      pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]After the unfortunate defeat, you scurry back home."))
    else
      pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]You scurry back home, protecting your exhausted Pokémon from any further harm..."))
    end
    if homedata
      pbCancelVehicles
      Followers.clear
      $game_switches[Settings::STARTING_OVER_SWITCH] = true
      $game_temp.player_new_map_id    = homedata[0]
      $game_temp.player_new_x         = homedata[1]
      $game_temp.player_new_y         = homedata[2]
      $game_temp.player_new_direction = homedata[3]
      $scene.transfer_player if $scene.is_a?(Scene_Map)
      $game_map.refresh
    else
      $player.heal_party
    end
  end
  pbEraseEscapePoint
end

class Pokemon
  def getEggMovesList
    baby = GameData::Species.get(species).get_baby_species
    egg = GameData::Species.get_species_form(baby,@form).egg_moves
    return egg
  end
  def has_egg_move?
    return false if egg? || shadowPokemon?
    getEggMovesList.each { |m| return true if !hasMove?(m[1]) }
    return false
  end
end

class EggRelearner_Scene
  VISIBLEMOVES = 4

  def pbDisplay(msg, brief = false)
    UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(pokemon, moves)
    @pokemon = pokemon
    @moves = moves
    moveCommands = []
    moves.each { |m| moveCommands.push(GameData::Move.get(m).name) }
    # Create sprite hash
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    addBackgroundPlane(@sprites, "bg", "reminderbg", @viewport)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x = 320
    @sprites["pokeicon"].y = 84
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/reminderSel")
    @sprites["background"].y = 78
    @sprites["background"].src_rect = Rect.new(0, 72, 258, 72)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["commands"] = Window_CommandPokemon.new(moveCommands, 32)
    @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
    @sprites["commands"].visible = false
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible = false
    @sprites["msgwindow"].viewport = @viewport
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    pbDrawMoveList
    pbDeactivateWindows(@sprites)
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawMoveList
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 400 : 366 + (70 * i)
      overlay.blt(type_x, 70, @typebitmap.bitmap, type_rect)
    end
    textpos = [
      [_INTL("Teach which move?"), 16, 14, 0, Color.new(88, 88, 80), Color.new(168, 184, 184)]
    ]
    imagepos = []
    yPos = 88
    VISIBLEMOVES.times do |i|
      moveobject = @moves[@sprites["commands"].top_item + i]
      if moveobject
        moveData = GameData::Move.get(moveobject)
        type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
        imagepos.push(["Graphics/Pictures/types", 12, yPos - 4, 0, type_number * 28, 64, 28])
        textpos.push([moveData.name, 80, yPos, 0, Color.new(248, 248, 248), Color.new(0, 0, 0)])
        textpos.push([_INTL("PP"), 112, yPos + 32, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        if moveData.total_pp > 0
          textpos.push([_INTL("{1}/{1}", moveData.total_pp), 230, yPos + 32, 1,
                        Color.new(64, 64, 64), Color.new(176, 176, 176)])
        else
          textpos.push(["--", 230, yPos + 32, 1, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        end
      end
      yPos += 64
    end
    imagepos.push(["Graphics/Pictures/reminderSel",
                   0, 78 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 64),
                   0, 0, 258, 72])
    selMoveData = GameData::Move.get(@moves[@sprites["commands"].index])
    basedamage = selMoveData.display_damage(@pokemon)
    category = selMoveData.display_category(@pokemon)
    accuracy = selMoveData.display_accuracy(@pokemon)
    textpos.push([_INTL("CATEGORY"), 272, 120, 0, Color.new(248, 248, 248), Color.new(0, 0, 0)])
    textpos.push([_INTL("POWER"), 272, 152, 0, Color.new(248, 248, 248), Color.new(0, 0, 0)])
    textpos.push([basedamage <= 1 ? basedamage == 1 ? "???" : "---" : sprintf("%d", basedamage),
                  468, 152, 2, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    textpos.push([_INTL("ACCURACY"), 272, 184, 0, Color.new(248, 248, 248), Color.new(0, 0, 0)])
    textpos.push([accuracy == 0 ? "---" : "#{accuracy}%",
                  468, 184, 2, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    pbDrawTextPositions(overlay, textpos)
    imagepos.push(["Graphics/Pictures/category", 436, 116, 0, category * 28, 64, 28])
    if @sprites["commands"].index < @moves.length - 1
      imagepos.push(["Graphics/Pictures/reminderButtons", 48, 350, 0, 0, 76, 32])
    end
    if @sprites["commands"].index > 0
      imagepos.push(["Graphics/Pictures/reminderButtons", 134, 350, 76, 0, 76, 32])
    end
    pbDrawImagePositions(overlay, imagepos)
    drawTextEx(overlay, 272, 216, 230, 5, selMoveData.description,
               Color.new(64, 64, 64), Color.new(176, 176, 176))
  end

  # Processes the scene
  def pbChooseMove
    oldcmd=-1
    pbActivateWindow(@sprites,"commands") {
      loop do
        oldcmd=@sprites["commands"].index
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["commands"].index!=oldcmd
          @sprites["background"].x=0
          @sprites["background"].y=78+(@sprites["commands"].index-@sprites["commands"].top_item)*64
          pbDrawMoveList
        end
        if Input.trigger?(Input::BACK)
          return nil
        elsif Input.trigger?(Input::USE)
          return @moves[@sprites["commands"].index]
        end
      end
    }
  end

  # End the scene here
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end
end

#===============================================================================
# Screen class for handling game logic
#===============================================================================
class EggRelearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbGetEggMoves(pkmn)
    return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
    moves = []
    pkmn.getEggMovesList.each do |m|
      next if pkmn.hasMove?(m)
      moves.push(m) if !moves.include?(m)
    end
    egg = moves
    return egg | []  # remove duplicates
  end

  def pbStartScreen(pkmn)
    moves = pbGetEggMoves(pkmn)
    @scene.pbStartScene(pkmn, moves)
    loop do
      move = @scene.pbChooseMove
      if move
        if @scene.pbConfirm(_INTL("Teach {1}?", GameData::Move.get(move).name))
          if pbLearnMove(pkmn, move)
            @scene.pbEndScene
            return true
          end
        end
      elsif @scene.pbConfirm(_INTL("Give up trying to teach a new move to {1}?", pkmn.name))
        @scene.pbEndScene
        return false
      end
    end
  end
end

def pbEggMoveScreen(pkmn)
  retval = true
  pbFadeOutIn {
    scene = EggRelearner_Scene.new
    screen = EggRelearnerScreen.new(scene)
    retval = screen.pbStartScreen(pkmn)
  }
  return retval
end

MenuHandlers.add(:party_menu, :relearn, {
  "name"      => _INTL("Relearn Moves"),
  "order"     => 31,
  "condition"   => proc { next $game_map.map_id == 32 && $game_switches[62]},
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    if pkmn.can_relearn_move?
      pbRelearnMoveScreen(pkmn)
    else
      screen.pbDisplay(_INTL("This Pokémon cannot relearn any moves."))
    end
  }
})

MenuHandlers.add(:party_menu, :egg_moves, {
  "name"      => _INTL("Teach Egg Moves"),
  "order"     => 32,
  "condition"   => proc { next $game_map.map_id == 32 && $game_switches[63] },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    if pkmn.has_egg_move?
      pbEggMoveScreen(pkmn)
    else
      screen.pbDisplay(_INTL("This Pokémon cannot relearn any moves."))
    end
  }
})