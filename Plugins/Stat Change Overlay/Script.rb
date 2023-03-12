class Bitmap
  attr_accessor :storedPath
end

class Battle::Scene::PokemonDataBox < SpriteWrapper
  def initializeOtherGraphics(viewport)
    # Create other bitmaps
    @numbersBitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/icon_numbers"))
    @hpBarBitmap   = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/overlay_hp"))
    @expBarBitmap  = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/overlay_exp"))
    @sprites["Atk"]  = Sprite.new(viewport)
    @sprites["Def"]  = Sprite.new(viewport)
    @sprites["SpAtk"]  = Sprite.new(viewport)
    @sprites["SpDef"]  = Sprite.new(viewport)
    @sprites["Spe"]  = Sprite.new(viewport)
    @sprites["Eva"]  = Sprite.new(viewport)
    @sprites["Acc"]  = Sprite.new(viewport)
    @sprites["Atk"].visible = false
    @sprites["Def"].visible = false
    @sprites["SpAtk"].visible = false
    @sprites["SpDef"].visible = false
    @sprites["Spe"].visible = false
    @sprites["Eva"].visible = false
    @sprites["Acc"].visible = false
    @sprites["Atk"].z = 99999
    @sprites["Def"].z = 99999
    @sprites["SpAtk"].z = 99999
    @sprites["SpDef"].z = 99999
    @sprites["Spe"].z = 99999
    @sprites["Eva"].z = 99999
    @sprites["Acc"].z = 99999
    # Create sprite to draw HP numbers on
    @hpNumbers = BitmapSprite.new(124, 16, viewport)
  #    pbSetSmallFont(@hpNumbers.bitmap)
    @sprites["hpNumbers"] = @hpNumbers
    # Create sprite wrapper that displays HP bar
    @hpBar = SpriteWrapper.new(viewport)
    @hpBar.bitmap = @hpBarBitmap.bitmap
    @hpBar.src_rect.height = @hpBarBitmap.height / 3
    @sprites["hpBar"] = @hpBar
    # Create sprite wrapper that displays Exp bar
    @expBar = SpriteWrapper.new(viewport)
    @expBar.bitmap = @expBarBitmap.bitmap
    @sprites["expBar"] = @expBar
    # Create sprite wrapper that displays everything except the above
    @contents = BitmapWrapper.new(@databoxBitmap.width, @databoxBitmap.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = 150 + ((@battler.index / 2) * 5)
    pbSetSystemFont(self.bitmap)
  end

  def pbBitmap(name)
    begin
      dir = name.split("/")[0...-1].join("/") + "/"
      file = name.split("/")[-1]
      bmp = RPG::Cache.load_bitmap(dir, file)
      bmp.storedPath = name
    rescue
      Console.echo _INTL("Image located at '#{name}' was not found!")
      bmp = Bitmap.new(2,2)
    end
    return bmp
  end

  def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    textPos = []
    imagePos = []
    stat_boost = []
    $stages = stat_boost
    # Draw background panel
    self.bitmap.blt(0, 0, @databoxBitmap.bitmap, Rect.new(0, 0, @databoxBitmap.width, @databoxBitmap.height))
    # Draw Pokémon's name
    nameWidth = self.bitmap.text_size(@battler.name).width
    nameOffset = 0
    nameOffset = nameWidth - 116 if nameWidth > 116
    textPos.push([@battler.name, @spriteBaseX + 8 - nameOffset, 12, false, NAME_BASE_COLOR, NAME_SHADOW_COLOR])
    # Draw Pokémon's gender symbol
    case @battler.displayGender
    when 0   # Male
      textPos.push([_INTL("♂"), @spriteBaseX + 126, 12, false, MALE_BASE_COLOR, MALE_SHADOW_COLOR])
    when 1   # Female
      textPos.push([_INTL("♀"), @spriteBaseX + 126, 12, false, FEMALE_BASE_COLOR, FEMALE_SHADOW_COLOR])
    end
    pbDrawTextPositions(self.bitmap, textPos)
    # Draw Pokémon's level
    imagePos.push(["Graphics/Pictures/Battle/overlay_lv", @spriteBaseX + 140, 16])
    pbDrawNumber(@battler.level, self.bitmap, @spriteBaseX + 162, 16)
    # Draw shiny icon
    if @battler.shiny?
      shinyX = (@battler.opposes?(0)) ? 206 : -6   # Foe's/player's
      imagePos.push(["Graphics/Pictures/shiny", @spriteBaseX + shinyX, 36])
    end
    # Draw Mega Evolution/Primal Reversion icon
    if @battler.mega?
      imagePos.push(["Graphics/Pictures/Battle/icon_mega", @spriteBaseX + 8, 34])
    elsif @battler.primal?
      primalX = (@battler.opposes?) ? 208 : -28   # Foe's/player's
      if @battler.isSpecies?(:KYOGRE)
        imagePos.push(["Graphics/Pictures/Battle/icon_primal_Kyogre", @spriteBaseX + primalX, 4])
      elsif @battler.isSpecies?(:GROUDON)
        imagePos.push(["Graphics/Pictures/Battle/icon_primal_Groudon", @spriteBaseX + primalX, 4])
      end
    end
    # Draw owned icon (foe Pokémon only)
    if @battler.owned? && @battler.opposes?(0)
      imagePos.push(["Graphics/Pictures/Battle/icon_own", @spriteBaseX + 8, 36])
    end
    i = @battler.stages[:ATTACK]
    j = @battler.stages[:DEFENSE]
    k = @battler.stages[:SPECIAL_ATTACK]
    l = @battler.stages[:SPECIAL_DEFENSE]
    m = @battler.stages[:SPEED]
    n = @battler.stages[:EVASION]
    o = @battler.stages[:ACCURACY]
    stat_boost.push(i)
    stat_boost.push(j)
    stat_boost.push(k)
    stat_boost.push(l)
    stat_boost.push(m)
    stat_boost.push(n)
    stat_boost.push(o)
    @stat_path_atk =  "Graphics/Pictures/Stat Overlay/Atk#{$stages[0]}"
    @stat_path_def = "Graphics/Pictures/Stat Overlay/Def#{$stages[1]}"
    @stat_path_spatk = "Graphics/Pictures/Stat Overlay/SpAtk#{$stages[2]}"
    @stat_path_spdef = "Graphics/Pictures/Stat Overlay/SpDef#{$stages[3]}"
    @stat_path_spe = "Graphics/Pictures/Stat Overlay/Spe#{$stages[4]}"
    @stat_path_eva = "Graphics/Pictures/Stat Overlay/Eva#{$stages[5]}"
    @stat_path_acc = "Graphics/Pictures/Stat Overlay/Acc#{$stages[6]}"
    statX = (@battler.opposes?) ? @spriteX + 220 : @spriteX - 44
    statY = @spriteY + 6
    if !pbInSafari?
      @sprites["Atk"].bitmap = $stages[0] != 0 ? pbBitmap(@stat_path_atk) : nil
      @sprites["Atk"].visible = $stages[0] != 0 ? true : false
      @sprites["Atk"].x = statX
      @sprites["Atk"].y = statY
      @sprites["Def"].bitmap = $stages[1] != 0 ? pbBitmap(@stat_path_def) : nil
      @sprites["Def"].visible = $stages[1] != 0 ? true : false
      @sprites["Def"].x = statX + 40
      @sprites["Def"].y = statY
      @sprites["SpAtk"].bitmap = $stages[2] != 0 ? pbBitmap(@stat_path_spatk) : nil
      @sprites["SpAtk"].visible = $stages[2] != 0 ? true : false
      @sprites["SpAtk"].x = (@battler.opposes?) ? statX + 20 : statX - 20
      @sprites["SpAtk"].y = statY + 16
      @sprites["SpDef"].bitmap = $stages[3] != 0 ? pbBitmap(@stat_path_spdef) : nil
      @sprites["SpDef"].visible = $stages[3] != 0 ? true : false
      @sprites["SpDef"].x = (@battler.opposes?) ? statX + 60 : statX + 20
      @sprites["SpDef"].y = statY + 16
      @sprites["Spe"].bitmap = $stages[4] != 0 ? pbBitmap(@stat_path_spe) : nil
      @sprites["Spe"].visible = $stages[4] != 0 ? true : false
      @sprites["Spe"].x = (@battler.opposes?) ? statX : statX - 40
      @sprites["Spe"].y = statY + 32
      @sprites["Eva"].bitmap = $stages[5] != 0 ? pbBitmap(@stat_path_eva) : nil
      @sprites["Eva"].visible = $stages[5] != 0 ? true : false
      @sprites["Eva"].x = (@battler.opposes?) ? statX + 40 : statX
      @sprites["Eva"].y = statY + 32
      @sprites["Acc"].bitmap = $stages[6] != 0 ? pbBitmap(@stat_path_acc) : nil
      @sprites["Acc"].visible = $stages[6] != 0 ? true : false
      @sprites["Acc"].x = (@battler.opposes?) ? statX + 80 : statX + 40
      @sprites["Acc"].y = statY + 32
    end
    # Draw status icon
    if @battler.status != :NONE
      if @battler.status == :POISON && @battler.statusCount > 0   # Badly poisoned
        s = GameData::Status.count - 1
      else
        s = GameData::Status.get(@battler.status).icon_position
      end
      if s >= 0
        imagePos.push(["Graphics/Pictures/Battle/icon_statuses", @spriteBaseX + 24, 36,
                       0, s * STATUS_ICON_HEIGHT, -1, STATUS_ICON_HEIGHT])
      end
    end
    pbDrawImagePositions(self.bitmap, imagePos)
    refreshHP
    refreshExp
  end
  def overlay_refresh
    stat_boost = []
    $stages = stat_boost
    i = @battler.stages[:ATTACK]
    j = @battler.stages[:DEFENSE]
    k = @battler.stages[:SPECIAL_ATTACK]
    l = @battler.stages[:SPECIAL_DEFENSE]
    m = @battler.stages[:SPEED]
    n = @battler.stages[:EVASION]
    o = @battler.stages[:ACCURACY]
    stat_boost.push(i)
    stat_boost.push(j)
    stat_boost.push(k)
    stat_boost.push(l)
    stat_boost.push(m)
    stat_boost.push(n)
    stat_boost.push(o)
    @stat_path_atk =  "Graphics/Pictures/Stat Overlay/Atk#{$stages[0]}"
    @stat_path_def = "Graphics/Pictures/Stat Overlay/Def#{$stages[1]}"
    @stat_path_spatk = "Graphics/Pictures/Stat Overlay/SpAtk#{$stages[2]}"
    @stat_path_spdef = "Graphics/Pictures/Stat Overlay/SpDef#{$stages[3]}"
    @stat_path_spe = "Graphics/Pictures/Stat Overlay/Spe#{$stages[4]}"
    @stat_path_eva = "Graphics/Pictures/Stat Overlay/Eva#{$stages[5]}"
    @stat_path_acc = "Graphics/Pictures/Stat Overlay/Acc#{$stages[6]}"
    statX = (@battler.opposes?) ? @spriteX + 220 : @spriteX - 44
    statY = @spriteY + 6
    if !pbInSafari?
      @sprites["Atk"].bitmap = $stages[0] != 0 ? pbBitmap(@stat_path_atk) : nil
      @sprites["Atk"].visible = $stages[0] != 0 ? true : false
      @sprites["Atk"].x = statX
      @sprites["Atk"].y = statY
      @sprites["Def"].bitmap = $stages[1] != 0 ? pbBitmap(@stat_path_def) : nil
      @sprites["Def"].visible = $stages[1] != 0 ? true : false
      @sprites["Def"].x = statX + 40
      @sprites["Def"].y = statY
      @sprites["SpAtk"].bitmap = $stages[2] != 0 ? pbBitmap(@stat_path_spatk) : nil
      @sprites["SpAtk"].visible = $stages[2] != 0 ? true : false
      @sprites["SpAtk"].x = (@battler.opposes?) ? statX + 20 : statX - 20
      @sprites["SpAtk"].y = statY + 16
      @sprites["SpDef"].bitmap = $stages[3] != 0 ? pbBitmap(@stat_path_spdef) : nil
      @sprites["SpDef"].visible = $stages[3] != 0 ? true : false
      @sprites["SpDef"].x = (@battler.opposes?) ? statX + 60 : statX + 20
      @sprites["SpDef"].y = statY + 16
      @sprites["Spe"].bitmap = $stages[4] != 0 ? pbBitmap(@stat_path_spe) : nil
      @sprites["Spe"].visible = $stages[4] != 0 ? true : false
      @sprites["Spe"].x = (@battler.opposes?) ? statX : statX - 40
      @sprites["Spe"].y = statY + 32
      @sprites["Eva"].bitmap = $stages[5] != 0 ? pbBitmap(@stat_path_eva) : nil
      @sprites["Eva"].visible = $stages[5] != 0 ? true : false
      @sprites["Eva"].x = (@battler.opposes?) ? statX + 40 : statX
      @sprites["Eva"].y = statY + 32
      @sprites["Acc"].bitmap = $stages[6] != 0 ? pbBitmap(@stat_path_acc) : nil
      @sprites["Acc"].visible = $stages[6] != 0 ? true : false
      @sprites["Acc"].x = (@battler.opposes?) ? statX + 80 : statX + 40
      @sprites["Acc"].y = statY + 32
    end
  end
  def update(frameCounter = 0)
    super()
    # Animate HP bar
    updateHPAnimation
    # Animate Exp bar
    updateExpAnimation
    # Update coordinates of the data box
    updatePositions(frameCounter)
    overlay_refresh
    pbUpdateSpriteHash(@sprites)
  end
end
