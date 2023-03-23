def pbTimeChanger
  $time_changer == 0 ? pbMessage(_INTL("Switch to what Time?\\ch[34,4,Night,Reset,Cancel]")) : pbMessage(_INTL("Switch to what Time?\\ch[34,4,Day,Reset,Cancel]"))
  t = $game_variables[34]
  $ret = 0
  case t
  when 0
    SetTime.stopped = true
    $time_changer += 1
    $time_changer = 0 if $time_changer >= TIME_CHANGE.size
    time = TIME_CHANGE[$time_changer]
    SetTime.set(Time.local(pbGetTimeNow.year,pbGetTimeNow.mon,pbGetTimeNow.day,time,0,0))
    $time_changer == 0 ? pbMessage(_INTL("Time set to Day.")) : pbMessage(_INTL("Time set to Night."))
    $time_update = true
  when 1
    SetTime.clear
    pbMessage(_INTL("Time reset."))
    $time_changer = PBDayNight.isNight? ? 1 : 0
    $time_update = true
  when -1,3,4
    pbPlayCloseMenuSE
    $time_update = false
  end
end

TIME_CHANGE = [10,22]
$time_changer = PBDayNight.isNight? ? 1 : 0
$time_update = false

#===============================================================================
# * Set the Time - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It allows to stop the time and/or
# manually set the current time.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin.
#
#== HOW TO USE =================================================================
#
# 'SetTime.set(new_time)' sets the time. new_time is a ruby Time object.
#
# 'SetTime.stopped = boolean' stop/unstop current time.
#
# 'SetTime.clear' Undo 'set' and 'stopped'.
#
# 'SetTime.ask(set_year,set_month,set_day,set_hour,set_minute)' asks player to
# manually set the time. All the parameters default values are 'true'.
#
# All of these script commands, so you should call using event script command.
#
#== EXAMPLES ===================================================================
#
# An example who sets the time to 2000 christmas eve (23:59) and stops the time:
#
#  SetTime.set(Time.local(2000, 12, 24, 23, 59))
#  SetTime.stopped = true
#
# An example who prompt the player to set the hour and minutes:
#
#  SetTime.ask(false,false,false)
#
#== NOTES ======================================================================
#
# If you wish to some parts still use real time like the Trainer Card start time
# and Pokémon Trainer Memo, just change 'pbGetTimeNow' to 'Time.now' in their
# scripts.
#
# This script uses the Ruby Time class. Before Essentials version 19 (who came
# with 64-bit ruby) it can only have 1901-2038 range.
#
#===============================================================================
=begin
if defined?(PluginManager) && !PluginManager.installed?("Set the Time")
  PluginManager.register({                                                 
    :name    => "Set the Time",                                        
    :version => "1.0",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=481401",             
    :credits => "FL",
    :incompatibilities => ["Unreal Time System"]
  })
end
=end
module SetTime
  MIN_YEAR = 1000 # Min year when manually set the time.
  MAX_YEAR = 2999 # Min year when ask to set the time.
  
  module_function

  def set(time) 
    if stopped
      $PokemonGlobal.temporary_time = time
      $PokemonGlobal.extra_time_seconds = 0
    else
      $PokemonGlobal.extra_time_seconds = time - getRealTimeNow
    end
    PBDayNight.shedule_tone_refresh
  end

  def stopped
    return $PokemonGlobal.temporary_time != nil
  end
  
  def stopped=(value)
    if value
      $PokemonGlobal.temporary_time = pbGetTimeNow 
    else
      $PokemonGlobal.extra_time_seconds = pbGetTimeNow - getRealTimeNow
      $PokemonGlobal.temporary_time = nil
    end
  end
  
  def clear
    $PokemonGlobal.extra_time_seconds = nil
    $PokemonGlobal.temporary_time = nil
  end

  def ask(
    set_year=true,set_month=true,set_day=true,set_hour=true,set_minute=true
  )
    loop do
      year = ask_year(pbGetTimeNow.year, set_year)
      month = ask_month(pbGetTimeNow.month, set_month)
      day = ask_day(pbGetTimeNow.day, set_day, year, month)
      hour = ask_hour(pbGetTimeNow.hour, set_hour)
      minute = ask_minute(pbGetTimeNow.min, set_minute)
      if set_year || set_month || set_day
        message = _ISPRINTF(
          "{1:02d}:{2:02d} {3:02d}/{4:02d}/{5:04d}?",hour,minute,day,month,year
        )
      else
        message = _ISPRINTF("{1:02d}:{2:02d}?",hour,minute)
      end
      if pbConfirmMessage(message)
        set(Time.local(year, month, day, hour, minute))
        break
      end
    end
  end

  def show_input_message(message, confirm_message, min, max, default)
    ret = default
    loop do
      params = ChooseNumberParams.new
      params.setRange(min, max)
      params.setInitialValue(ret)
      ret = pbMessageChooseNumber(message, params)
      return ret if pbConfirmMessage(confirm_message.gsub("(value)", ret.to_s))
    end
  end

  def ask_year(default, should_set)
    ret = default
    if should_set
      ret = show_input_message(
        _INTL("Select year."), _INTL("The year is (value)?"),
        min_year, max_year, ret
      )
    end
    return ret
  end

  def min_year
    ret = MIN_YEAR
    ret = [MIN_YEAR, 1902].max if need_year_limit
    return ret
  end

  def max_year
    ret = MAX_YEAR
    ret = [MAX_YEAR, 2037].min if need_year_limit
    return ret
  end

  def need_year_limit
    version = 0
    version = Essentials::VERSION.split(".")[0].to_i if defined?(Essentials)
    return version<19
  end

  def ask_month(default, should_set)
    ret = default
    if should_set
      ret = show_input_message(
        _INTL("Select month."), _INTL("The month is (value)?"), 1, 12, ret
      )
    end
    return ret
  end

  def ask_day(default, should_set, year, month)
    ret = [last_month_day(year, month),[1,default].max].min # make sure
    if should_set
      ret = show_input_message(
        _INTL("Select day."), _INTL("The day is (value)?"), 
        1, last_month_day(year, month), ret
      )
    end
    return ret
  end

  def last_month_day(year, month)
    return case month
      when 1,3,5,7,8,10,12; 31
      when 4,6,9,11;        30
      when 2;               year%4==0 ? 29 : 28
    end
  end

  def ask_hour(default, should_set)
    ret = default
    if should_set
      ret = show_input_message(
        _INTL("Select hours (0-23)."),_INTL("(value) hours?"),0,23,ret
      )
    end
    return ret
  end

  def ask_minute(default, should_set)
    ret = default
    if should_set
      ret = show_input_message(
        _INTL("Select minutes."),_INTL("(value) minutes?"),0,23,ret
      )
    end
    return ret
  end
  
  def get_time
    return getRealTimeNow if !$PokemonGlobal
    return $PokemonGlobal.temporary_time if $PokemonGlobal.temporary_time
    ret = getRealTimeNow
    if $PokemonGlobal.extra_time_seconds && $PokemonGlobal.extra_time_seconds!=0
      ret += $PokemonGlobal.extra_time_seconds
    end
    return ret
  end
end

alias :getRealTimeNow :pbGetTimeNow
def pbGetTimeNow
  return SetTime.get_time
end

module PBDayNight
  class << self
    if method_defined?(:getTone)
      alias :_old_fl_getTone :getTone
      def getTone
        if @day_night_tone_need_update && Settings::TIME_SHADING
          getToneInternal
          @day_night_tone_need_update = false
        end
        return _old_fl_getTone
      end
    end

    # Shedule a tone refresh on the next try (probably next frame)
    def shedule_tone_refresh
      @day_night_tone_need_update = true
    end
  end
end

class PokemonGlobalMetadata
  attr_accessor :temporary_time
  attr_accessor :extra_time_seconds
end