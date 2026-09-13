// Kino Challenge Configurator -- Plutonium T5 host/server script.
// Use the init() entry point from the supplied working Zombies extension.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;

init()
{
	if ( IsDefined( level.kino_challenges_loaded ) || level.script != "zombie_theater" )
	{
		return;
	}

	level.kino_challenges_loaded = true;
	level.kino_challenge_rules = [];
	level.kino_challenge_hud = [];
	level.kino_challenge_random_count = 0;
	level.kino_challenge_menu_locked = false;
	kinoRegisterRules();

	// This is the stock callback used by maps\_zombiemode::round_start().
	// It runs before the begin_spawning flag is set.
	level.round_prestart_func = ::kinoChallengePrestart;
}

kinoRegisterRules()
{
	kinoAddRule( "no_jug", "No Jug" );
	kinoAddRule( "no_perks", "No Perks" );
	kinoAddRule( "no_power", "No Power" );
	kinoAddRule( "no_pack_a_punch", "No Pack-a-Punch" );
	kinoAddRule( "no_mystery_box", "No Mystery Box" );
	kinoAddRule( "no_thunder_gun", "No Thunder Gun" );
	kinoAddRule( "starting_room_only", "Starting Room Only" );
	kinoAddRule( "wall_weapons_only", "Wall Weapons Only" );
}

kinoAddRule( key, label )
{
	rule = SpawnStruct();
	rule.key = key;
	rule.label = label;
	rule.enabled = false;
	level.kino_challenge_rules[level.kino_challenge_rules.size] = rule;
}

kinoDisableTarget( targetname )
{
	triggers = GetEntArray( targetname, "targetname" );
	for ( i = 0; i < triggers.size; i++ )
	{
		triggers[i] disable_trigger();
	}
}

kinoDisableJug()
{
	triggers = GetEntArray( "zombie_vending", "targetname" );
	for ( i = 0; i < triggers.size; i++ )
	{
		if ( triggers[i].script_noteworthy == "specialty_armorvest" || triggers[i].script_noteworthy == "specialty_armorvest_upgrade" )
		{
			triggers[i] disable_trigger();
		}
	}
}

kinoDisableThunderGun()
{
	if ( IsDefined( level.zombie_weapons["thundergun_zm"] ) )
	{
		level.zombie_weapons["thundergun_zm"].is_in_box = false;
	}
	if ( IsDefined( level.zombie_include_weapons["thundergun_zm"] ) )
	{
		level.zombie_include_weapons["thundergun_zm"] = false;
	}
}

kinoApplyRule( key )
{
	switch ( key )
	{
		case "no_jug": kinoDisableJug(); break;
		case "no_perks": kinoDisableTarget( "zombie_vending" ); break;
		case "no_power": kinoDisableTarget( "use_elec_switch" ); break;
		case "no_pack_a_punch": kinoDisableTarget( "zombie_vending_upgrade" ); break;
		case "no_mystery_box": kinoDisableTarget( "treasure_chest_use" ); break;
		case "no_thunder_gun": kinoDisableThunderGun(); break;
		case "starting_room_only":
			kinoDisableTarget( "zombie_door" );
			kinoDisableTarget( "zombie_debris" );
			break;
		case "wall_weapons_only": kinoDisableTarget( "treasure_chest_use" ); break;
	}
}

kinoShowLockedRules()
{
	hud = CreateServerFontString( "objective", 1.05 );
	hud SetPoint( "RIGHT", "TOP", -18, 48 );
	hud SetText( "KINO CHALLENGE RULES" );
	hud.color = ( 0.25, 0.85, 1 );
	count = 0;
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( level.kino_challenge_rules[i].enabled )
		{
			hud = CreateServerFontString( "objective", 1.05 );
			hud SetPoint( "RIGHT", "TOP", -18, 68 + ( count * 18 ) );
			hud SetText( "- " + level.kino_challenge_rules[i].label );
			hud.color = ( 1, 0.72, 0.2 );
			count++;
		}
	}
	if ( count == 0 )
	{
		hud = CreateServerFontString( "objective", 1.05 );
		hud SetPoint( "RIGHT", "TOP", -18, 68 );
		hud SetText( "- No restrictions" );
	}
}

kinoChooseRandomRules()
{
	indices = [];
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		level.kino_challenge_rules[i].enabled = false;
		indices[i] = i;
	}
	for ( i = 0; i < level.kino_challenge_random_count; i++ )
	{
		pick = i + RandomInt( level.kino_challenge_rules.size - i );
		temp = indices[i];
		indices[i] = indices[pick];
		indices[pick] = temp;
		level.kino_challenge_rules[indices[i]].enabled = true;
	}
}

kinoLockRules()
{
	if ( level.kino_challenge_menu_locked )
	{
		return;
	}
	if ( level.kino_challenge_random_count > 0 )
	{
		kinoChooseRandomRules();
	}
	level.kino_challenge_menu_locked = true;
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( level.kino_challenge_rules[i].enabled )
		{
			kinoApplyRule( level.kino_challenge_rules[i].key );
		}
	}
	for ( i = 0; i < level.kino_challenge_hud.size; i++ )
	{
		level.kino_challenge_hud[i] destroyElem();
	}
	kinoShowLockedRules();
}

kinoRefreshMenu( selected, confirming )
{
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		prefix = "  ";
		if ( selected == i )
		{
			prefix = "> ";
		}
		state = "OFF";
		if ( level.kino_challenge_rules[i].enabled )
		{
			state = "ON";
		}
		level.kino_challenge_hud[i + 1] SetText( prefix + level.kino_challenge_rules[i].label + ": " + state );
	}
	i = level.kino_challenge_rules.size;
	prefix = "  ";
	if ( selected == i )
	{
		prefix = "> ";
	}
	level.kino_challenge_hud[i + 1] SetText( prefix + "Random N Rules: " + level.kino_challenge_random_count );
	i++;
	prefix = "  ";
	if ( selected == i )
	{
		prefix = "> ";
	}
	if ( confirming )
	{
		level.kino_challenge_hud[i + 1] SetText( "> START GAME? A / Use: confirm | B: back" );
	}
	else
	{
		level.kino_challenge_hud[i + 1] SetText( prefix + "START GAME (locks settings)" );
	}
}

kinoMakeMenu()
{
	level.kino_challenge_hud = [];
	hud = CreateServerFontString( "objective", 1.6 );
	hud SetPoint( "CENTER", "CENTER", 0, -145 );
	hud SetText( "KINO CHALLENGE CONFIGURATION" );
	level.kino_challenge_hud[0] = hud;
	for ( i = 0; i < level.kino_challenge_rules.size + 2; i++ )
	{
		hud = CreateServerFontString( "objective", 1.2 );
		hud SetPoint( "CENTER", "CENTER", 0, -110 + ( i * 22 ) );
		level.kino_challenge_hud[i + 1] = hud;
	}
	hud = CreateServerFontString( "objective", 1.0 );
	hud SetPoint( "CENTER", "CENTER", 0, 145 );
	hud SetText( "Host: D-pad navigate / change | A select | B back | Clients: view-only" );
	level.kino_challenge_hud[level.kino_challenge_hud.size] = hud;
}

kinoHostMenu( host )
{
	selected = 0;
	last = level.kino_challenge_rules.size + 1;
	confirming = false;
	// Commands verified in storage/t5/players/config.cfg. These listeners
	// observe gameplay bindings; they do not rebind the controller.
	host notifyonplayercommand( "kino_next", "+actionslot 2" );
	host notifyonplayercommand( "kino_previous", "+actionslot 1" );
	host notifyonplayercommand( "kino_decrease", "+actionslot 3" );
	host notifyonplayercommand( "kino_increase", "+actionslot 4" );
	host notifyonplayercommand( "kino_select", "+gostand" );
	// B is melee in Tactical and stance in Default. Both commands go back.
	host notifyonplayercommand( "kino_back", "+melee" );
	host notifyonplayercommand( "kino_back", "+stance" );
	// Retain the existing keyboard / mouse controls.
	host notifyonplayercommand( "kino_next", "+attack" );
	host notifyonplayercommand( "kino_previous", "+speed_throw" );
	host notifyonplayercommand( "kino_select", "+activate" );
	for ( ;; )
	{
		kinoRefreshMenu( selected, confirming );
		input = host waittill_any_return( "kino_next", "kino_previous", "kino_select", "kino_decrease", "kino_increase", "kino_back" );
		if ( level.kino_challenge_menu_locked )
		{
			return;
		}
		if ( confirming )
		{
			if ( input == "kino_back" )
			{
				confirming = false;
			}
			else if ( input == "kino_select" )
			{
				return;
			}
			continue;
		}
		// This is the root menu; B only backs out of start confirmation.
		if ( input == "kino_back" )
		{
			continue;
		}
		if ( input == "kino_next" )
		{
			selected++;
			if ( selected > last )
			{
				selected = 0;
			}
			continue;
		}
		if ( input == "kino_previous" )
		{
			selected--;
			if ( selected < 0 )
			{
				selected = last;
			}
			continue;
		}
		if ( selected < level.kino_challenge_rules.size )
		{
			if ( input == "kino_decrease" )
			{
				level.kino_challenge_rules[selected].enabled = false;
			}
			else if ( input == "kino_increase" )
			{
				level.kino_challenge_rules[selected].enabled = true;
			}
			else if ( input == "kino_select" )
			{
				level.kino_challenge_rules[selected].enabled = !level.kino_challenge_rules[selected].enabled;
			}
			continue;
		}
		if ( selected == level.kino_challenge_rules.size )
		{
			if ( input == "kino_decrease" )
			{
				level.kino_challenge_random_count--;
			}
			else
			{
				level.kino_challenge_random_count++;
			}
			if ( level.kino_challenge_random_count < 0 )
			{
				level.kino_challenge_random_count = level.kino_challenge_rules.size;
			}
			if ( level.kino_challenge_random_count > level.kino_challenge_rules.size )
			{
				level.kino_challenge_random_count = 0;
			}
			continue;
		}
		if ( input == "kino_select" )
		{
			confirming = true;
		}
	}
}

kinoChallengePrestart()
{
	if ( level.kino_challenge_menu_locked )
	{
		return;
	}
	host = get_host();
	if ( !IsDefined( host ) )
	{
		kinoLockRules();
		return;
	}
	kinoMakeMenu();
	host freezecontrols( false );
	kinoHostMenu( host );
	kinoLockRules();
}
