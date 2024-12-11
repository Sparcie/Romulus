# Romulus

Romulus is a computer player for the play-by-email game VGA Planets 3. It plays as the shareware player
with all the limitations that apply. It is not feature complete, but it does set up a decent economy, control the starships
and build defenses and starbases. It has a rudimentary diplomacy system where it can decide to wage war or ask for peace.

### Building

I built Romulus using Borland Turbo Pascal 7 under MS-DOS. You can build it for either real-mode or DPMI. I haven't tried but it should build with something like free pascal.

### Usage

Romulus has no command line parameters, it will read and create turn files for any result files found. It does require some
data files from the VGA Planets distribution. Generally the files included with the shareware client are suitable, but if 
your game is running a custom map, ships or ship components you'll need to use that data instead.

 - _fizz.bin_ - registration information for the client. The shareware one will work as this is a shareware player.
 - _beamspec.dat_ - stores data for the beam weapons
 - _engspec.dat_ - stores data for the engines
 - _torpspec.dat_ - stores data for torpedo tubes
 - _hullspec.dat_ - stores data for ship hulls
 - _truehull.dat_ - stores a list of which hulls belong to each faction.
 - _xyplan.dat_ - stores a map of all the planet locations.

Romulus reads any RST file in the current directory and generates a TRN file for that player. Some state information
is stored in a file named `ship?.rom`, where ? is the player identifier. It generates a temporary file `msgout.log` that
contains the messages from the last player processed. This is to save memory if you compile this for a real-mode DOS target.

You'll need to run Romulus either on a real MS-DOS machine or within an emulator such as DOSBox. 
I've found it's best to create a separate directory to store the data files and executable so you don't accidentally
interfere with other players RST and TRN files.

### Diplomacy

Romulus will communicate with other players using the in-game message system. You can interact with it by sending it
a message in response.

 - send `ROMU WAR` to declare war on the Romulus player.
 - send `ROMU OFFER CEASE` to offer it a cease fire
 - send `ROMU OFFER PEACE` to offer it a peace treaty
 - send `ROMU ACCEPT CEASE` to accept a cease fire
 - send `ROMU ACCEPT PEACE` to accept a peace treaty
 - send `ROMU ASSIST x` to ask for assistance against player x (1..11)

### License
Romulus is public domain.
