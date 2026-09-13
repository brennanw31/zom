// Temporary diagnostic: install IN PLACE OF the full kino_challenges.gsc.
// Follows the user's working init -> connected -> spawned_player example.
// Does not change rounds, weapons, player health, or challenge settings.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include common_scripts\utility;

init()
{
	Print( "[KINO PROBE] init entered" );
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread onConnect();
	}
}

onConnect()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );
	self probeDirectCall();
	callback = ::probeCallback;
	self [[callback]]();
}

probeDirectCall()
{
	Print( "[KINO PROBE] direct local call passed" );
	self iPrintLn( "Kino probe: direct local call passed" );
}

probeCallback()
{
	Print( "[KINO PROBE] local callback passed" );
	self iPrintLn( "Kino probe: local callback passed" );
}
