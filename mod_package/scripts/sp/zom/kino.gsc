// Kino Challenge Configurator -- host/server extension for Plutonium T5.
#include scripts\sp\zom\kino_config;
#include scripts\sp\zom\kino_menu;

init()
{
	if ( IsDefined( level.kino_loaded ) || level.script != "zombie_theater" )
		return;
	level.kino_loaded = true;
	scripts\sp\zom\kino_config::kinoChallengesInitialize();
	level.round_prestart_func = scripts\sp\zom\kino_menu::kinoChallengePrestart;
}