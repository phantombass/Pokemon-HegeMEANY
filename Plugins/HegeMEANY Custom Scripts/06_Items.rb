ItemHandlers::UseOnPokemon.add(:IVMAXSTONE,proc { |item,pkmn,scene|
  choices = []
  for i in 0...6
    choices.push(_INTL(GameData::Stat.get(i).name))
  end
  choices.push(_INTL("Cancel"))
  command = pbMessage("Which IV would you like to max out?",choices,choices.length)
  statChoice = (command == 6) ? -1 : command
  next false if statChoice == -1
  if pkmn.iv[statChoice] == 31
    scene.pbDisplay(_INTL("This stat is already maxed out!"))
    return false
  end
  stat = GameData::Stat.get(statChoice).id
  statDisp = GameData::Stat.get(statChoice).name
    pkmn.iv[stat] = 31
    pkmn.calc_stats
    scene.pbDisplay(_INTL("{1}'s {2} IVs were maxed out!",pkmn.name,statDisp))
  next true
})

ItemHandlers::UseOnPokemon.add(:IVMINSTONE,proc { |item,pkmn,scene|
  choices = []
  for i in 0...6
    choices.push(_INTL(GameData::Stat.get(i).name))
  end
  choices.push(_INTL("Cancel"))
  command = pbMessage("Which IV would you like to zero out?",choices,choices.length)
  statChoice = (command == 6) ? -1 : command
  next false if statChoice == -1
  if pkmn.iv[statChoice] == 0
    scene.pbDisplay(_INTL("This stat is already zeroed out!"))
    return false
  end
  stat = GameData::Stat.get(statChoice).id
  statDisp = GameData::Stat.get(statChoice).name
    pkmn.iv[stat] = 0
    pkmn.calc_stats
    scene.pbDisplay(_INTL("{1}'s {2} IVs were zeroed out!",pkmn.name,statDisp))
  next true
})