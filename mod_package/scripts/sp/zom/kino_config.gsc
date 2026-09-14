// Challenge definitions and pre-game selection state.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;

kinoChallengesInitialize()
{
	level.kino_challenge_rules = [];
	level.kino_challenge_perks = [];
	level.kino_challenge_boons = [];
	level.kino_challenge_playtest = [];
	level.kino_challenge_hud = [];
	level.kino_challenge_random_count = 0;
	level.kino_challenge_cooldown = 0;
	level.kino_challenge_menu_locked = false;
	kinoRegisterRules();
	kinoRegisterPerks();
	kinoRegisterBoons();
	kinoRegisterPlaytest();
}

kinoRegisterRules()
{
	kinoAddRule( "no_power", "No Power" );
	kinoAddRule( "no_pack_a_punch", "No Pack-a-Punch" );
	kinoAddRule( "no_mystery_box", "No Mystery Box" );
	kinoAddRule( "no_thunder_gun", "No Thunder Gun" );
	kinoAddRule( "starting_room_only", "Starting Room Only" );
	kinoAddRule( "no_walkers", "No Walkers" );
	kinoAddRule( "no_window_barricades", "No Window Barricades" );
	kinoAddRule( "spawn_rate", "Spawn Rate" );
	kinoAddRule( "horde_size", "Horde Size" );
	kinoAddRuleSuppression( "no_mystery_box", "no_thunder_gun" );
	kinoAddRuleSuppression( "no_power", "no_pack_a_punch" );
	kinoAddRuleSuppression( "starting_room_only", "no_power" );
	kinoAddRuleSuppression( "starting_room_only", "no_mystery_box" );
}

kinoAddRule( key, label )
{
	rule = SpawnStruct();
	rule.key = key;
	rule.label = label;
	rule.enabled = false;
	rule.suppressed_rules = [];
	level.kino_challenge_rules[level.kino_challenge_rules.size] = rule;
}

kinoFindRule( key )
{
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( level.kino_challenge_rules[i].key == key )
			return level.kino_challenge_rules[i];
	}
	return undefined;
}

kinoAddRuleSuppression( source_key, suppressed_key )
{
	rule = kinoFindRule( source_key );
	if ( IsDefined( rule ) )
		rule.suppressed_rules[rule.suppressed_rules.size] = suppressed_key;
}

kinoRuleSuppresses( source_key, target_key )
{
	rule = kinoFindRule( source_key );
	if ( !IsDefined( rule ) )
		return false;
	for ( i = 0; i < rule.suppressed_rules.size; i++ )
	{
		if ( rule.suppressed_rules[i] == target_key || kinoRuleSuppresses( rule.suppressed_rules[i], target_key ) )
			return true;
	}
	return false;
}

kinoRuleIsSuppressed( key )
{
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		rule = level.kino_challenge_rules[i];
		if ( rule.enabled && rule.key != key && kinoRuleSuppresses( rule.key, key ) )
			return true;
	}
	return false;
}

kinoPowerUnavailable()
{
	rule = kinoFindRule( "no_power" );
	return rule.enabled || kinoRuleIsSuppressed( "no_power" );
}

kinoRegisterBoons()
{
	options = [];
	options[0] = "Normal";
	options[1] = "+1";
	options[2] = "+2";
	options[3] = "+3";
	kinoAddBoon( "health", "Health", options );
	options = [];
	options[0] = "Normal";
	options[1] = "+10%%";
	options[2] = "+20%%";
	options[3] = "+50%%";
	options[4] = "+100%%";
	kinoAddBoon( "damage", "Damage", options );
	options = [];
	options[0] = "Off";
	options[1] = "Unlimited";
	kinoAddBoon( "sprint", "Sprint", options );
	options = [];
	options[0] = "Normal";
	options[1] = "+5%%";
	options[2] = "+10%%";
	options[3] = "+15%%";
	kinoAddBoon( "movement", "Movement Speed", options );
	options = [];
	options[0] = "Normal";
	options[1] = "+10%%";
	options[2] = "+20%%";
	options[3] = "+50%%";
	options[4] = "+100%%";
	kinoAddBoon( "income", "Income", options );
}

kinoAddBoon( key, label, options )
{
	boon = SpawnStruct();
	boon.key = key;
	boon.label = label;
	boon.options = options;
	boon.selected = 0;
	level.kino_challenge_boons[level.kino_challenge_boons.size] = boon;
}

kinoRegisterPlaytest()
{
	options = [];
	options[0] = "Off";
	options[1] = "On";
	kinoAddPlaytestOption( "god_mode", "God Mode", options );
	options = [];
	options[0] = "1";
	options[1] = "10";
	options[2] = "20";
	options[3] = "50";
	kinoAddPlaytestOption( "starting_round", "Starting Round", options );
	options = [];
	options[0] = "None";
	options[1] = "HK21";
	options[2] = "Raygun";
	options[3] = "Thundergun";
	kinoAddPlaytestOption( "weapon", "Give Weapon", options );
	options = [];
	options[0] = "No";
	options[1] = "Yes";
	kinoAddPlaytestOption( "points", "Give Points", options );
	options = [];
	options[0] = "No";
	options[1] = "Yes";
	kinoAddPlaytestOption( "infinite_ammo", "Infinite Ammo", options );
}

kinoAddPlaytestOption( key, label, options )
{
	option = SpawnStruct();
	option.key = key;
	option.label = label;
	option.options = options;
	option.selected = 0;
	level.kino_challenge_playtest[level.kino_challenge_playtest.size] = option;
}

kinoRegisterPerks()
{
	kinoAddPerk( "specialty_armorvest", "Juggernog" );
	kinoAddPerk( "specialty_quickrevive", "Quick Revive" );
	kinoAddPerk( "specialty_fastreload", "Speed Cola" );
	kinoAddPerk( "specialty_rof", "Double Tap" );
	kinoAddPerk( "specialty_longersprint", "Stamin-Up" );
	kinoAddPerk( "specialty_flakjacket", "PhD Flopper" );
	kinoAddPerk( "specialty_deadshot", "Deadshot Daiquiri" );
	kinoAddPerk( "specialty_additionalprimaryweapon", "Mule Kick" );
}

kinoAddPerk( key, label )
{
	perk = SpawnStruct();
	perk.key = key;
	perk.label = label;
	perk.enabled = false; // true means RESTRICTED, consistent with challenge toggles
	perk.present = false;
	level.kino_challenge_perks[level.kino_challenge_perks.size] = perk;
}

kinoFindPerks()
{
	triggers = GetEntArray( "zombie_vending", "targetname" );
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		perk = level.kino_challenge_perks[i];
		perk.present = false;
		for ( j = 0; j < triggers.size; j++ )
		{
			if ( IsDefined( triggers[j].script_noteworthy ) &&
				( triggers[j].script_noteworthy == perk.key || triggers[j].script_noteworthy == perk.key + "_upgrade" ) )
				perk.present = true;
		}
	}
}

kinoSetAllPerks( restricted )
{
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
		level.kino_challenge_perks[i].enabled = restricted && level.kino_challenge_perks[i].present;
}

kinoPerkCount()
{
	count = 0;
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		if ( level.kino_challenge_perks[i].enabled && kinoPerkRestrictionRelevant( level.kino_challenge_perks[i] ) )
			count++;
	}
	return count;
}

kinoPerkRestrictionRelevant( perk )
{
	if ( !kinoPowerUnavailable() )
		return true;
	return perk.key == "specialty_quickrevive" && get_players().size == 1;
}

kinoHasRelevantPerks()
{
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		if ( kinoPerkRestrictionRelevant( level.kino_challenge_perks[i] ) )
			return true;
	}
	return false;
}

kinoBoonLabel( boon )
{
	return boon.options[boon.selected];
}

kinoBoonCycle( boon, step )
{
	boon.selected = kinoWrap( boon.selected + step, boon.options.size );
}

kinoBoonValue( key )
{
	for ( i = 0; i < level.kino_challenge_boons.size; i++ )
	{
		if ( level.kino_challenge_boons[i].key == key )
			return level.kino_challenge_boons[i].selected;
	}
	return 0;
}

kinoPlaytestValue( key )
{
	for ( i = 0; i < level.kino_challenge_playtest.size; i++ )
	{
		if ( level.kino_challenge_playtest[i].key == key )
			return level.kino_challenge_playtest[i].selected;
	}
	return 0;
}

kinoRandomPool()
{
	pool = [];
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
		pool[pool.size] = level.kino_challenge_rules[i];
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		if ( level.kino_challenge_perks[i].present )
			pool[pool.size] = level.kino_challenge_perks[i];
	}
	return pool;
}

kinoChooseRandomRules()
{
	pool = kinoRandomPool();
	kinoSetAllPerks( false );
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
		level.kino_challenge_rules[i].enabled = false;
	count = level.kino_challenge_random_count;
	if ( count > pool.size )
		count = pool.size;
	for ( i = 0; i < count; i++ )
	{
		pick = i + RandomInt( pool.size - i );
		temp = pool[i];
		pool[i] = pool[pick];
		pool[pick] = temp;
		pool[i].enabled = true;
	}
}

kinoWrap( value, count )
{
	if ( value < 0 )
		return count - 1;
	if ( value >= count )
		return 0;
	return value;
}

kinoToggle( rule, input )
{
	if ( input == "kino_decrease" )
		rule.enabled = false;
	else if ( input == "kino_increase" )
		rule.enabled = true;
	else
		rule.enabled = !rule.enabled;
}