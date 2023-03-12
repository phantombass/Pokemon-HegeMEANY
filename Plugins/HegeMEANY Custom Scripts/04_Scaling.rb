EventHandlers.add(:on_trainer_load, :level_scale,
  proc { |trainer|
    if trainer
      party = trainer.pokemon_party
      mlv = $Trainer.party.map { |e| e.level  }.max
      for pokemon in party
        level = 0
        level = 1 if level < 2
        level = mlv - rand(3)
        pokemon.level = level
        pokemon.calc_stats
      end #end of for
    end
  }
)