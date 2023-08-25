# Welcome to Sonic Pi v2.6
# world-o-techno
# Acid sample coded by Sam Aaron
# Hacked around by RS & JHR
# Modified by rixx to run on a list of waypoints instead of a real GPS
# Enter your coordinates in the waypoints array below

# See http://www.jarkman.co.uk/catalog/robots/worldotechno.htm and
# https://github.com/jarkman/world-o-techno for background

waypoints = [
  [53.0322, 13.3104],  # CCCamp23
  [52.0392, -2.378],  # EMF
]

class Gps
  attr_accessor :speed, :satellites, :latitude, :initialTime
  
  def initialize(waypoints)
    @speed = 0.0001
    @satellites = 10
    @initialTime = Time.now
    @waypoints = waypoints
    @waypointIndex = 0
  end
  
  def latitude
    @startLat = @waypoints[@waypointIndex][0]
    @endLat = @waypoints[@waypointIndex+1][0]
    stepsTaken = ((Time.now - @initialTime) / 10 ).floor
    @resultLat = @startLat + @speed * stepsTaken
    if (@resultLat > @endLat && @startLat < @endLat) || (@resultLat < @endLat && @startLat > @endLat)
      @waypointIndex = @waypointIndex + 1
      if @waypointIndex >= @waypoints.length - 2
        @waypointIndex = 0
      end
      @initialTime = Time.now
      @resultLat = @waypoints[@waypointIndex][0]
    end
    return @resultLat
  end
  
  def longitude
    @startLon = @waypoints[@waypointIndex][1]
    @endLon = @waypoints[@waypointIndex+1][1]
    stepsTaken = ((Time.now - @initialTime) / 10 ).floor
    @resultLon = @startLon + @speed * stepsTaken
    if (@resultLon > @endLon && @startLon < @endLon) || (@resultLon < @endLon && @startLon > @endLon)
      @waypointIndex = @waypointIndex + 1
      if @waypointIndex >= @waypoints.length - 2
        @waypointIndex = 0
      end
      @initialTime = Time.now
      @resultLon = @waypoints[@waypointIndex][1]
    end
    return @resultLon
  end
end

# Creating a dummy GPS object
# Waypoints are a list of [latitude, longitude] pairs
gps = Gps.new(waypoints)

# in pitch order to give a systematic variation as you move
chords = [:a1, :c1, :e1, :a2, :c2, :e2, :a3, :c3, :e3, :a4, :c4, :e4 ]

define :chooseChord do |chooser|
  i = (chooser/5) % chords.size# about 5 feet per chord

c = chords[i];
  print c
  return c
end

define :gpsSatelliteCount do
  s = 0;
  if gps != nil && gps.satellites != nil &&  gps.satellites != 0
    s = gps.satellites.count
  end
  return s;
end

define :gotFix do
  g = false;

  #print "gps in gotFix"
  #print gps

  if gps != nil 
    g = gps.latitude != nil && gps.latitude != 0
  end

  return g
end

define :lat do
  
  l = 0.0
  if gps != nil && gps.latitude != nil
    l = gps.latitude
  end
  #print "lat"
  #print l
  return l
end


define :lon do
  l = 0.0
  if gps != nil && gps.longitude != nil
    l = gps.longitude
  end
  #print "lon"
  #print l
  return l
end

define :latInt do
# Convert latitude to a suitable number, which will vary by about 1 for a sensible small movement
# One degree is 111325m (at the equator)
# We'd like to see about a foot, 0.3m, so we'll want a factor of 300000
# Our GPS report better resolution than that, about 10**-9 degree, but that's not very repeatable
  l =  lat().abs * 300000
  l = l.round
  #print "latInt"
  #print l
  return l
end

define :lonInt do
  l =  lon().abs * 300000
  l = l.round
  #print "lonInt"
  #print l
  return l
end


define :speed do
  l = 0.0
  if gps != nil && gps.speed != nil
    l = gps.speed
  end
  return l
end

define :locationRelease do |r|
  # Scale our parameter up or down by a factor of 2 depending on location
  factor = (latInt() + lonInt()) % 30  # varies from 0 to 30 over distance of 10m
  factor = (factor / 30) + 0.5 # varies from 0.5 to 1.5 over 10m
  return r * factor
end

sleep 2
load_sample :bd_fat
load_sample :bd_boom
load_sample :bd_haus

define :playSatelliteCount do
  # More satellites, more thumps, so we can hear the process of acquisition
    i = 0
    print ":playSatelliteCount"
    4.times do
      c = gpsSatelliteCount()
      if i == 0
        sample :bd_boom, amp:10
      else
        if i <= c
          sample :bd_fat, amp: 6
        else
          sample :bd_haus, amp: 1
        end
      end

      sleep 0.5
      i = i+1
    end

end

define :playTune do
  print ":playTune"

  cue :foo

  
  4.times do |i|
    long = lonInt() % 100
    use_random_seed long
    4.times do
      sample :bd_fat, amp: 5
      loopChord = chooseChord( lonInt() % 656753 ) # Pick chord from position on each bar so we hear motion sooner
      use_random_seed lonInt() % 257867 # Use a selection of large primes to get different seeds hence different tunes for each loop
      4.times do
        use_synth :tb303
        play chord(loopChord, :minor).choose, attack: 0, release: locationRelease(0.1), cutoff: rrand_i(50, 90) + i * 10
        sleep 0.125
      end
    end
  end

  if ! gotFix()
    return
  end

  cue :bar
  use_synth :tb303
  
  8.times do |i|
    sample :bd_fat, amp: 5
    use_random_seed latInt() % 1412041
    loopChord = chooseChord( lonInt() % 656753 )
    4.times do
      gspeed = speed().modulo(1)
      play chord(loopChord, :minor).choose, attack: 0, release: locationRelease(0.05), cutoff: rrand_i(70, 98) + i, res: gspeed
      sleep 0.125
    end
  end

  if ! gotFix()
    return
  end

  cue :baz
  with_fx :reverb, mix: 0.3 do |r|
    
    8.times do |m|
      sample :bd_fat, amp: 5
      use_random_seed (lonInt() + latInt()) % 2256197
      loopChord = chooseChord( latInt() % 656753 )
      4.times do
        control r, mix: 0.3 + (0.5 * (m.to_f / 32.0)) unless m == 0 if m % 8 == 0
        use_synth :prophet
        play chord(loopChord, :minor).choose, attack: 0, release: locationRelease(0.08), cutoff: rrand_i(110, 130)
        sleep 0.125
      end
    end
  end

  if ! gotFix()
    return
  end

  cue :quux
  in_thread do
    
    4.times do
      sample :bd_fat, amp: 5
      slat = latInt().modulo(1) + 0.1
      use_random_seed lonInt() % 9562447
      loopChord = chooseChord( lonInt() % 656753 )
      with_fx :slicer, mix: 0.75, wave: 3, phase: slat do
        4.times do
          use_synth :tb303
          play chord(loopChord, :major).choose, attack: 0, release: locationRelease(0.1), cutoff: rrand(50, 100)
          sleep 0.25
        end
      end
    end
  end

  if ! gotFix()
    return
  end
 
    sleep 4
  end
 


loop do
  if gotFix() 
    playTune()
  else
    playSatelliteCount()
  end
end
