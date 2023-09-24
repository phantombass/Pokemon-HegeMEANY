class PBAI
	def self.log_spam(msg)
		echoln "[AI Spam Block] " + msg
	end
  class SpamHandler
    @@GeneralCode = []

	  def self.add(&code)
	   	@@GeneralCode << code
	 	end

	 	def self.set(list,flag,ai,battler,target)
	 		return flag if list.nil?
	 		list = [list] if !list.is_a?(Array)
			list.each do |code|
	  	next if code.nil?
	  		add_flag = code.call(flag,ai,battler,target)
	  		flag = add_flag
	  	end
		  return flag
		end

		def self.trigger(flag,ai,battler,target)
			return self.set(@@GeneralCode,flag,ai,battler,target)
		end
  end
end

#Triple Switch
PBAI::SpamHandler.add do |flag,ai,battler,target|
  if !$spam_block_triggered
		triple_switch = $spam_block_flags[:triple_switch]
		PBAI.log_spam("Triple Switch: #{triple_switch}")
		next flag if triple_switch.length < 3
		check = 0
		for i in triple_switch
			check += 1 if !i.nil?
			check = 0 if i.nil?
			$spam_block_flags[:triple_switch].clear if check == 0
			$spam_block_flags[:choice] = nil if check == 0
		end
		if check == 3
			flag = true
			$spam_block_triggered = true
			$spam_block_flags[:triple_switch].clear
		end
		PBAI.log("[AI] Triple Switch: #{$spam_block_flags[:triple_switch]}")
		PBAI.log("[AI] Player move choice: #{$spam_block_flags[:choice]}")
	end
	next flag
end

#Double Initiative
PBAI::SpamHandler.add do |flag,ai,battler,target|
	if !$spam_block_triggered
		initative = ["SwitchOutTargetStatusMove", "SwitchOutTargetDamagingMove", "SwitchOutUserDamagingMove","LowerTargetAtkSpAtk1SwitchOutUser","SwitchOutUserStartHailWeather","UserMakeSubstituteSwitchOut"]
		same_move = $spam_block_flags[:initiative_flag]
		PBAI.log_spam("Double Initiative: #{same_move}")
		next flag if same_move.length < 2
		check = 0
		for i in same_move
			check += 1 if initiative.include?(i.function)
			check = 0 if !initiative.include?(i.function)
			$spam_block_flags[:initiative_flag].clear if check == 0
			$spam_block_flags[:choice] = nil if check == 0
		end
		if check == 2
			flag = true
			$spam_block_triggered = true
			$spam_block_flags[:initiative_flag].clear
		end
		PBAI.log("[AI] Double Initiative: #{$spam_block_flags[:initiative_flag]}")
		PBAI.log("[AI] Player move choice: #{$spam_block_flags[:choice]}")
	end
	next flag
end

#Double Recover
PBAI::SpamHandler.add do |flag,ai,battler,target|
	if !$spam_block_triggered
		recover = ["HealUserHalfOfTotalHP", "HealUserHalfOfTotalHPLoseFlyingTypeThisTurn", "HealUserPositionNextTurn","HealUserDependingOnWeather","HealUserDependingOnSandstorm"]
		same_move = $spam_block_flags[:double_recover]
		PBAI.log_spam("Double Recover: #{same_move}")
		next flag if same_move.length < 2
		check = 0
		for i in same_move
			check += 1 if recover.include?(i.function)
			check = 0 if !recover.include?(i.function)
			$spam_block_flags[:double_recover].clear if check == 0
			$spam_block_flags[:choice] = nil if check == 0
		end
		if check == 2
			flag = true
			$spam_block_triggered = true
			$spam_block_flags[:double_recover].clear
		end
		PBAI.log("[AI] Double Recover: #{$spam_block_flags[:double_recover]}")
		PBAI.log("[AI] Player move choice: #{$spam_block_flags[:choice]}")
	end
	next flag
end

#Same Move
PBAI::SpamHandler.add do |flag,ai,battler,target|
  if !$spam_block_triggered
		next flag if $spam_block_flags[:choiced_flag].include?(target)
		same_move = $spam_block_flags[:same_move]
		PBAI.log_spam("Triple Move: #{same_move}")
		next flag if same_move.length < 3
		check = 0
		for i in 1...same_move.length
			check += 1 if same_move[i] == same_move[i-1]
			check = 0 if same_move[i] != same_move[i-1]
			$spam_block_flags[:same_move].clear if check == 0
			$spam_block_flags[:choice] = nil if check == 0
		end
		if check == 2
			flag = true
			$spam_block_triggered = true
			$spam_block_flags[:same_move].clear
		end
		PBAI.log("[AI] Triple Move: #{$spam_block_flags[:same_move]}")
		PBAI.log("[AI] Player move choice: #{$spam_block_flags[:choice]}")
	end
	next flag
end

#Double Stat Drop
PBAI::SpamHandler.add do |flag,ai,battler,target|
	if !$spam_block_triggered
		double_stat = $spam_block_flags[:double_intimidate]
		PBAI.log_spam("Double Intimidate: #{double_stat}")
		next flag if double_stat.length < 2
		check = 0
		for i in double_stat
			check += 1 if [:INTIMIDATE,:MEDUSOID,:MINDGAMES].include?(i)
			check = 0 if ![:INTIMIDATE,:MEDUSOID,:MINDGAMES].include?(i)
			$spam_block_flags[:double_intimidate].clear if check == 0
			$spam_block_flags[:choice] = nil if check == 0
		end
		if check == 2
			flag = true
			$spam_block_triggered = true
			$spam_block_flags[:double_intimidate].clear
		end
		PBAI.log("[AI] Double Intimidate: #{$spam_block_flags[:double_intimidate]}")
		PBAI.log("[AI] Player move choice: #{$spam_block_flags[:choice]}")
	end
	next flag
end

#Protect into Switch
PBAI::SpamHandler.add do |flag,ai,battler,target|
	if !$spam_block_triggered
		protect_switch = $spam_block_flags[:protect_switch]
		PBAI.log_spam("Protect into Switch: #{protect_switch}")
		next flag if protect_switch.length < 2
		check = 0
		for i in 1...protect_switch.length
			flag = (protect_switch[i] == :Switch && protect_switch[i-1].is_a?(Battle::Move::ProtectUser))
		end
		PBAI.log("[AI] Protect into Switch: #{$spam_block_flags[:protect_switch]}")
	end
	next flag
end

#Switch to Ghost on Fake Out
PBAI::SpamHandler.add do |flag,ai,battler,target|
	if !$spam_block_triggered
		protect_switch = $spam_block_flags[:fake_out_ghost_flag]
		PBAI.log_spam("Switch to Fake Out Immune: #{protect_switch}")
		next flag if protect_switch.length < 2
		flag = protect_switch.length == 2
		PBAI.log("[AI] Switch to Fake Out Immune: #{$spam_block_flags[:fake_out_ghost_flag]}")
	end
	next flag
end