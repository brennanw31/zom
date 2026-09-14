// Host input flow and the transition from configuration to active rules.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;
#include scripts\sp\zom\kino_config;
#include scripts\sp\zom\kino_gameplay;
#include scripts\sp\zom\kino_hud;

kinoLockRules()
{
	if ( level.kino_challenge_menu_locked )
		return;
	if ( level.kino_challenge_random_count > 0 )
		scripts\sp\zom\kino_config::kinoChooseRandomRules();
	level.kino_challenge_menu_locked = true;
	scripts\sp\zom\kino_gameplay::kinoApplyPerks();
	level.kino_boon_health_bonus = scripts\sp\zom\kino_config::kinoBoonValue( "health" ) * 50;
	level.kino_boon_damage_scale = scripts\sp\zom\kino_gameplay::kinoDamageScale();
	level.kino_boon_movement_scale = 1 + scripts\sp\zom\kino_config::kinoBoonValue( "movement" ) * 0.05;
	level.kino_boon_unlimited_sprint = scripts\sp\zom\kino_config::kinoBoonValue( "sprint" ) == 1;
	level.kino_boon_income_scale = scripts\sp\zom\kino_gameplay::kinoIncomeScale();
	scripts\sp\zom\kino_gameplay::kinoApplyIncomeBoon();
	scripts\sp\zom\kino_gameplay::kinoApplyHealthBoonHook();
	players = get_players();
	scripts\sp\zom\kino_gameplay::kinoApplyPlaytestStartingRound();
	for ( i = 0; i < players.size; i++ )
	{
		scripts\sp\zom\kino_gameplay::kinoApplyPlayerBoons( players[i] );
		scripts\sp\zom\kino_gameplay::kinoApplyPlaytest( players[i] );
	}
	if ( scripts\sp\zom\kino_config::kinoBoonValue( "damage" ) > 0 )
		scripts\sp\zom\kino_gameplay::kinoApplyDamageBoon();
	scripts\sp\zom\kino_gameplay::kinoApplySelectedRules();
	scripts\sp\zom\kino_gameplay::kinoApplyCooldown();
	for ( i = 0; i < level.kino_challenge_hud.size; i++ )
		level.kino_challenge_hud[i] destroyElem();
	scripts\sp\zom\kino_hud::kinoShowLockedRules();
}

// Pure menu state changes: no game effects are applied until Start is confirmed.
kinoHandleInput( menu, input )
{
	if ( level.kino_challenge_menu_locked || menu.done )
		return;
	if ( menu.confirming )
	{
		if ( input == "kino_back" )
			menu.confirming = false;
		else if ( input == "kino_select" )
			menu.done = true;
		return;
	}
	if ( input == "kino_back" )
	{
		if ( menu.page == "categories" )
			return;
		if ( menu.page == "boons" || menu.page == "playtest" || menu.page == "main" )
			menu.page = "categories";
		else
			menu.page = "main";
		menu.selected = 0;
		return;
	}
	entries = scripts\sp\zom\kino_hud::kinoMenuEntries( menu );
	if ( input == "kino_next" || input == "kino_previous" )
	{
		step = 1;
		if ( input == "kino_previous" )
			step = -1;
		menu.selected = scripts\sp\zom\kino_config::kinoWrap( menu.selected + step, entries.size );
		return;
	}
	if ( input != "kino_select" && input != "kino_decrease" && input != "kino_increase" )
		return;
	entry = entries[menu.selected];
	if ( menu.page == "categories" )
	{
		if ( input == "kino_select" || input == "kino_increase" )
		{
			if ( entry.kind == "category_boons" )
				menu.page = "boons";
			else
				menu.page = "main";
			menu.selected = 0;
		}
		return;
	}
	if ( menu.page == "boons" )
	{
		if ( entry.kind == "back_categories" && input == "kino_select" )
		{
			menu.page = "categories";
			menu.selected = 0;
		}
		else if ( entry.kind == "playtest" )
		{
			if ( input == "kino_select" || input == "kino_increase" )
			{
				menu.page = "playtest";
				menu.selected = 0;
			}
		}
		else if ( entry.kind == "boon" )
		{
			boon = level.kino_challenge_boons[entry.index];
			step = 1;
			if ( input == "kino_decrease" )
				step = -1;
			scripts\sp\zom\kino_config::kinoBoonCycle( boon, step );
		}
		return;
	}
	if ( menu.page == "playtest" )
	{
		if ( entry.kind == "back_boons" && input == "kino_select" )
		{
			menu.page = "boons";
			menu.selected = 0;
		}
		else if ( entry.kind == "playtest_option" )
		{
			option = level.kino_challenge_playtest[entry.index];
			step = 1;
			if ( input == "kino_decrease" )
				step = -1;
			scripts\sp\zom\kino_config::kinoBoonCycle( option, step );
		}
		return;
	}
	if ( menu.page == "perks" )
	{
		if ( entry.kind == "allow_perks" && input == "kino_select" )
			scripts\sp\zom\kino_config::kinoSetAllPerks( false );
		else if ( entry.kind == "restrict_perks" && input == "kino_select" )
			scripts\sp\zom\kino_config::kinoSetAllPerks( true );
		else if ( entry.kind == "back_main" && input == "kino_select" )
		{
			menu.page = "main";
			menu.selected = 0;
		}
		else if ( entry.kind == "perk" )
		{
			perk = level.kino_challenge_perks[entry.index];
			if ( perk.present )
				scripts\sp\zom\kino_config::kinoToggle( perk, input );
		}
		return;
	}
	if ( entry.kind == "perks" )
	{
		if ( input == "kino_select" || input == "kino_increase" )
		{
			menu.page = "perks";
			menu.selected = 0;
		}
		return;
	}
	if ( entry.kind == "rule" )
	{
		scripts\sp\zom\kino_config::kinoToggle( level.kino_challenge_rules[entry.index], input );
		return;
	}
	if ( entry.kind == "start" )
	{
		if ( input == "kino_select" )
			menu.confirming = true;
		return;
	}
	step = 1;
	if ( input == "kino_decrease" )
		step = -1;
	if ( entry.kind == "cooldown" )
		level.kino_challenge_cooldown = scripts\sp\zom\kino_config::kinoWrap( level.kino_challenge_cooldown + step, 2 );
	else if ( entry.kind == "random" )
	{
		pool = scripts\sp\zom\kino_config::kinoRandomPool();
		level.kino_challenge_random_count = scripts\sp\zom\kino_config::kinoWrap( level.kino_challenge_random_count + step, pool.size + 1 );
	}
}

kinoNormalizeMenuSelection( menu )
{
	entries = scripts\sp\zom\kino_hud::kinoMenuEntries( menu );
	if ( menu.selected >= entries.size )
		menu.selected = entries.size - 1;
}

kinoHostMenu( host )
{
	menu = SpawnStruct();
	menu.page = "categories";
	menu.selected = 0;
	menu.confirming = false;
	menu.done = false;
	host notifyonplayercommand( "kino_next", "+actionslot 2" );
	host notifyonplayercommand( "kino_previous", "+actionslot 1" );
	host notifyonplayercommand( "kino_decrease", "+actionslot 3" );
	host notifyonplayercommand( "kino_increase", "+actionslot 4" );
	host notifyonplayercommand( "kino_select", "+gostand" );
	host notifyonplayercommand( "kino_back", "+melee" );
	host notifyonplayercommand( "kino_back", "+stance" );
	host notifyonplayercommand( "kino_next", "+attack" );
	host notifyonplayercommand( "kino_previous", "+speed_throw" );
	host notifyonplayercommand( "kino_select", "+activate" );
	while ( !menu.done && !level.kino_challenge_menu_locked )
	{
		kinoNormalizeMenuSelection( menu );
		scripts\sp\zom\kino_hud::kinoRefreshMenu( menu );
		input = host waittill_any_return( "kino_next", "kino_previous", "kino_select", "kino_decrease", "kino_increase", "kino_back" );
		kinoHandleInput( menu, input );
	}
}

kinoChallengePrestart()
{
	if ( level.kino_challenge_menu_locked )
		return;
	scripts\sp\zom\kino_config::kinoFindPerks();
	host = get_host();
	if ( !IsDefined( host ) )
	{
		kinoLockRules();
		return;
	}
	scripts\sp\zom\kino_hud::kinoMakeMenu();
	host freezecontrols( false );
	kinoHostMenu( host );
	kinoLockRules();
}