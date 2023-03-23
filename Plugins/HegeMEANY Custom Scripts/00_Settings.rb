module Settings
  #UPDATE THIS WITH EVERY PUSH!!!!!!!!!!!!!!
  GAME_VERSION = "1.0.17"
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
    if @list == 0
      @list = []
      return false
    end
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
    $DEBUG = true
    $NO_ACCESS = true
    $game_variables[97] = read_run_count
    write_run_count
  end
  def self.load(save_data)
    validate save_data => Hash
    SaveData.load_all_values(save_data)
    $stats.play_sessions += 1
    self.load_map
    pbAutoplayOnSave
    $map_log = MapLog.new
    $map_log.setup
    $DEBUG = true
    $NO_ACCESS = true
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
    mon = money + run*25000
    f.write("#{mon}")
  }
end

def write_run
  File.open("run.txt", "wb") { |f|
    floor = [80,82,83,84,85,86,87,88]
	idx = 0
    for i in floor
      idx += 1
      break if $game_map.map_id == i
    end
    idx = 7 if idx > 7
    idx = 0 if !floor.include?($game_map.map_id)
    run = idx
    f.write("#{run}")
  }
end

def write_run_count
  File.open("run_count.txt", "wb") { |f|
    run = $game_variables[97]
    run += 1
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

def read_run_count
  File.open("run_count.txt", "rb") { |f|
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
    SaveData.delete_file
    $game_temp.title_screen_calling = true
  else
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

class PokemonSummary_Scene
  def drawPageFour
   overlay = @sprites["overlay"].bitmap
    base   = Color.new(248,248,248)
    shadow = Color.new(104,104,104)
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage > 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136,96,72) if change[1] > 0
        statshadows[change[0]] = Color.new(64,120,152) if change[1] < 0
      end
    end
    evtable = Marshal.load(Marshal.dump(@pokemon.ev))
    ivtable = Marshal.load(Marshal.dump(@pokemon.iv))
    evHP = evtable[@pokemon.ev.keys[0]]
    ivHP = ivtable[@pokemon.iv.keys[0]]
    evAt = evtable[@pokemon.ev.keys[1]]
    ivAt = ivtable[@pokemon.iv.keys[1]]
    evDf = evtable[@pokemon.ev.keys[2]]
    ivDf = ivtable[@pokemon.iv.keys[2]]
    evSa = evtable[@pokemon.ev.keys[3]]
    ivSa = ivtable[@pokemon.iv.keys[3]]
    evSd = evtable[@pokemon.ev.keys[4]]
    ivSd = ivtable[@pokemon.iv.keys[4]]
    evSp = evtable[@pokemon.ev.keys[5]]
    ivSp = ivtable[@pokemon.iv.keys[5]]
    textpos = [
       [_INTL("HP"),292,82,2,base,statshadows[:HP]],
       [sprintf("%d/%d",evHP,ivHP),462,82,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Attack"),248,126,0,base,statshadows[:ATTACK]],
       [sprintf("%d/%d",evAt,ivAt),456,126,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Defense"),248,158,0,base,statshadows[:DEFENSE]],
       [sprintf("%d/%d",evDf,ivDf),456,158,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Sp. Atk"),248,190,0,base,statshadows[:SPECIAL_ATTACK]],
       [sprintf("%d/%d",evSa,ivSa),456,190,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Sp. Def"),248,222,0,base,statshadows[:SPECIAL_DEFENSE]],
       [sprintf("%d/%d",evSd,ivSd),456,222,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Speed"),248,254,0,base,statshadows[:SPEED]],
       [sprintf("%d/%d",evSp,ivSp),456,254,1,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Ability"),224,290,0,base,shadow]
    ]
    ability = @pokemon.ability
    if ability
      textpos.push([ability.name,362,290,0,Color.new(64,64,64),Color.new(176,176,176)])
      drawTextEx(overlay,224,322,282,2,ability.description,Color.new(64,64,64),Color.new(176,176,176))
    end
    pbDrawTextPositions(overlay,textpos)
  end

  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    moveBase   = Color.new(64,64,64)
    moveShadow = Color.new(176,176,176)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248,192,0),    # 1/2 of total PP or less
                Color.new(248,136,32),   # 1/4 of total PP or less
                Color.new(248,72,72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144,104,0),   # 1/2 of total PP or less
                Color.new(144,72,24),   # 1/4 of total PP or less
                Color.new(136,48,48)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    textpos  = []
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 104
    for i in 0...Pokemon::MAX_MOVES
      move=@pokemon.moves[i]
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push(["Graphics/Pictures/types", 248, yPos - 4, 0, type_number * 28, 64, 28])
        textpos.push([move.name,316,yPos,0,moveBase,moveShadow])
        if move.total_pp>0
          textpos.push([_INTL("PP"),342,yPos+32,0,moveBase,moveShadow])
          ppfraction = 0
          if move.pp==0;                  ppfraction = 3
          elsif move.pp*4<=move.total_pp; ppfraction = 2
          elsif move.pp*2<=move.total_pp; ppfraction = 1
          end
          textpos.push([sprintf("%d/%d",move.pp,move.total_pp),460,yPos+32,1,ppBase[ppfraction],ppShadow[ppfraction]])
        end
      else
        textpos.push(["-",316,yPos,0,moveBase,moveShadow])
        textpos.push(["--",442,yPos+32,1,moveBase,moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end
  def drawPageFiveSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    moveBase   = Color.new(64, 64, 64)
    moveShadow = Color.new(176, 176, 176)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248, 192, 0),    # 1/2 of total PP or less
                Color.new(248, 136, 32),   # 1/4 of total PP or less
                Color.new(248, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144, 104, 0),   # 1/2 of total PP or less
                Color.new(144, 72, 24),   # 1/4 of total PP or less
                Color.new(136, 48, 48)]   # Zero PP
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_movedetail")
    end
    # Write various bits of text
    textpos = [
      [_INTL("MOVES"), 26, 22, 0, base, shadow],
      [_INTL("CATEGORY"), 20, 128, 0, base, shadow],
      [_INTL("POWER"), 20, 160, 0, base, shadow],
      [_INTL("ACCURACY"), 20, 192, 0, base, shadow]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 104
    yPos -= 76 if move_to_learn
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    limit.times do |i|
      move = @pokemon.moves[i]
      if i == Pokemon::MAX_MOVES
        move = move_to_learn
        yPos += 20
      end
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push(["Graphics/Pictures/types", 248, yPos - 4, 0, type_number * 28, 64, 28])
        textpos.push([move.name, 316, yPos, 0, moveBase, moveShadow])
        if move.total_pp > 0
          textpos.push([_INTL("PP"), 342, yPos + 32, 0, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 460, yPos + 32, 1, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 316, yPos, 0, moveBase, moveShadow])
        textpos.push(["--", 442, yPos + 32, 1, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
    # Draw Pokémon's type icon(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 130 : 96 + (70 * i)
      overlay.blt(type_x, 78, @typebitmap.bitmap, type_rect)
    end
  end
  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFiveSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base = Color.new(64, 64, 64)
    shadow = Color.new(176, 176, 176)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.display_damage(@pokemon)
    when 0 then textpos.push(["---", 216, 160, 1, base, shadow])   # Status move
    when 1 then textpos.push(["???", 216, 160, 1, base, shadow])   # Variable power move
    else        textpos.push([selected_move.display_damage(@pokemon).to_s, 216, 160, 1, base, shadow])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 216, 192, 1, base, shadow])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 216 + overlay.text_size("%").width, 192, 1, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/Pictures/category", 166, 124, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 4, 224, 230, 5, selected_move.description, base, shadow)
  end
  def pbScene
    GameData::Species.play_cry_from_pokemon(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
        GameData::Species.play_cry_from_pokemon(@pokemon)
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @page==5
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
      elsif Input.trigger?(Input::UP) && @partyindex>0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 5 if @page<1
        @page = 1 if @page>5
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 1 if @page<1
        @page = 5 if @page>5
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end
end