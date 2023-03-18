class PokemonGlobalMetadata
  attr_accessor :randomizedData
end

class Randomizer
	def self.all_species
	    keys = []
	    GameData::Species.each { |species| keys.push(species.id) if species.form == 0 }
	    return keys
	end

	def self.levelRand
		lvl = [5,10,20,25,30,40,45,50]
		return lvl[rand(lvl.length)]
	end

	def self.getRandomizedData(data, symbol, index = nil)
	    if $PokemonGlobal && $PokemonGlobal.randomizedData && $PokemonGlobal.randomizedData.has_key?(symbol)
	      return $PokemonGlobal.randomizedData[symbol][index] if !index.nil?
	      return $PokemonGlobal.randomizedData[symbol]
	    end
	    return data
	  end

	def self.randomizeEncounters
	    # loads map encounters
	    data = load_data("Data/encounters.dat")
	    return if !data.is_a?(Hash) # failsafe
	    # iterates through each map point
	    for key in data.keys
	      # go through each encounter type
	      for type in data[key].types.keys
	        # cycle each definition
	        for i in 0...data[key].types[type].length
	          # set randomized species
	          data[key].types[type][i][1] = self.all_species.sample
	        end
	      end
	    end
	    $game_variables[61] = data
	    return data
	end

	def self.randomizeStarters
	  # if defined as an exclusion rule, species will not be randomized
	  # randomizes static encounters
	  species = self.all_species
	  starters = []
	  starter_names = []
	  loop do
		 mon = species[rand(species.length)]
		 starters.push(mon) if !starters.include?(mon)
		 break if starters.length == 3
	  end
	  for i in 0...starters.length
	  	starter_names.push(starters[i].name)
	  end
	  $game_variables[65] = starters
	  $game_variables[62] = starter_names[0]
	  $game_variables[63] = starter_names[1]
	  $game_variables[64] = starter_names[2]
	  return starters
	end

	def self.randomizeTrainers
        list = [:HIKER,:FISHERMAN,:LASS,:YOUNGSTER,:LADY,:BUGCATCHER,:GENTLEMAN,:RUINMANIAC,:PSYCHIC_M,:ENGINEER,:SCIENTIST,:SUPERNERD,:BURGLAR,
            :BLACKBELT,:CRUSHGIRL,:TUBER_F,:BIRDKEEPER,:TAMER,:CHANELLER]
        boss = ["Allen","Jacub","Ash","Hestia","Ducky","Phantombass"]
        chosen = []
        ver = []
        pick = 0
        loop do
            c = rand(list.length)
            choice = list[c]
            next if chosen.include?(choice)
            chosen.push(choice)
            pick += 1
            break if pick == 14
        end
        $game_switches[117] = true if rand(100) > 90
        for i in 0...chosen.length
            l = 0
            vers = []
            loop do
                num = rand(5)
                next if vers.include?(num)
                vers.push(num)
                l += 1
                break if l == 3
            end
            ver.push(vers)
        end
        $game_variables[80] = chosen
        $game_variables[81] = boss[rand(boss.length)]
        $game_variables[82] = vers
        $game_switches[200] = true if ["Ash","Hestia"].include?($game_variables[81])
    end
end

def getTrainerType
    trainer_types = $game_variables[80]
    prev = $game_variables[85]
    ret = trainer_types[prev+1]
    $game_variables[85] += 1
    if $game_variables[85] > trainer_types.length-1
        $game_variables[86] += 1
        $game_variables[85] = -1
    end
    return ret
end

def trainerForm(trainer_type,num)
    form = $game_variables[82]
    tr = $game_variables[80]
    idx = 0
    for i in tr
        break if i == trainer_type
        idx += 1
    end
    return form[idx][num]
end

def randomizeSpecies(species, static = false, gift = false)
  pokemon = nil
  if species.is_a?(Pokemon)
    pokemon = species.clone
    species = pokemon.species
  end
  if !pokemon.nil?
    pokemon.species = species
    pokemon.calc_stats
    pokemon.reset_moves
  end
  return pokemon.nil? ? species : pokemon
end

alias pbBattleOnStepTaken_randomizer pbBattleOnStepTaken unless defined?(pbBattleOnStepTaken_randomizer)
def pbBattleOnStepTaken(*args)
  $nonStaticEncounter = true
  pbBattleOnStepTaken_randomizer(*args)
  $nonStaticEncounter = false
end
#===============================================================================
#  aliasing to randomize static battles
#===============================================================================
class WildBattle
  # Used when walking in tall grass, hence the additional code.
  def self.start(*args, can_override: false)
    foe_party = WildBattle.generate_foes(*args)
    # Potentially call a different WildBattle.start-type method instead (for
    # roaming Pokémon, Safari battles, Bug Contest battles)
    spec = Randomizer.all_species
    foe_party[0].species = spec[rand(spec.length)]
    foe_party[0].level = Randomizer.levelRand
    foe_party[0].reset_moves
    foe_party[0].calc_stats
    if foe_party.length == 1 && can_override
      handled = [nil]
      EventHandlers.trigger(:on_calling_wild_battle, foe_party[0].species, foe_party[0].level, handled)
      return handled[0] if !handled[0].nil?
    end
    # Perform the battle
    outcome = WildBattle.start_core(*foe_party)
    # Used by the Poké Radar to update/break the chain
    if foe_party.length == 1 && can_override
      EventHandlers.trigger(:on_wild_battle_end, foe_party[0].species, foe_party[0].level, outcome)
    end
    # Return false if the player lost or drew the battle, and true if any other result
    return outcome != 2 && outcome != 5
  end
end