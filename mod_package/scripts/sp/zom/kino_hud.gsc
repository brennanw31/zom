// Menu and locked-rule HUD construction.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;
#include scripts\sp\zom\kino_config;
#include scripts\sp\zom\kino_gameplay;

kinoActiveLine( label, row )
{
	hud = CreateServerFontString( "objective", 1.0 );
	hud.fontscale = 1.0;
	hud SetPoint( "TOPLEFT", "TOPLEFT", 14, 18 + row * 14 );
	hud SetText( label );
	return hud;
}

kinoShowLockedRules()
{
	// Check if any playtest selections are made
	playtest_options_selected = false;
	for( i = 0; i < level.kino_challenge_playtest.size; i++ )
		if( level.kino_challenge_playtest[i].selected != 0 )
			playtest_options_selected = true;

	// Check if any boon selections are made
	boon_options_selected = false;
	for( i = 0; i < level.kino_challenge_boons.size; i++ )
		if( level.kino_challenge_boons[i].selected != 0 )
			boon_options_selected = true;

	// Check if any curse selections are made
	curse_options_selected = false;
	for( i = 0; i < level.kino_challenge_rules.size; i++ )
		if( level.kino_challenge_rules[i].enabled )
			curse_options_selected = true;
	for( i = 0; i < level.kino_challenge_perks.size; i++ )
		if( level.kino_challenge_perks[i].enabled )
			curse_options_selected = true;
	if( scripts\sp\zom\kino_config::kinoEscalationValue() != 0 )
		curse_options_selected = true;

	// Display nothing if no selections are made
	if( !playtest_options_selected
     && !boon_options_selected
	 && !curse_options_selected )
	 	return;

	// GAME RULE Header
	row = 0;
	hud = kinoActiveLine( "GAME RULES", row );
	hud.color = ( 0.25, 0.85, 1 ); // Blue
	row++;

	// PLAYTEST header - hide if none are selected
	if( playtest_options_selected )
	{
		hud = kinoActiveLine( "PLAYTEST", row );
		hud.color = ( 0.85, 0.25, 0.85 ); // Magenta
		row++;
		for ( i = 0; i < level.kino_challenge_playtest.size; i++ )
		{
			if ( level.kino_challenge_playtest[i].selected != 0 )
			{
				kinoActiveLine( "+ " + level.kino_challenge_playtest[i].label + ": " +
					level.kino_challenge_playtest[i].options[level.kino_challenge_playtest[i].selected], row );
				row++;
			}
		}
	}

	// BOONS header - hide if none are selected
	if( boon_options_selected )
	{
		hud = kinoActiveLine( "BOONS", row );
		hud.color = ( 0.25, 0.85, 0.25 ); // Green
		row++;

		// Individual BOON rows
		for ( i = 0; i < level.kino_challenge_boons.size; i++ )
		{
			if ( level.kino_challenge_boons[i].selected != 0 )
			{
				kinoActiveLine( "+ " + level.kino_challenge_boons[i].label + ": " +
					scripts\sp\zom\kino_config::kinoBoonLabel( level.kino_challenge_boons[i] ), row );
				row++;
			}
		}
	}

	// CURSES header - hide if none are selected
	if( curse_options_selected )
	{
		hud = kinoActiveLine( "CURSES", row );
		hud.color = ( 0.85, 0.25, 0.25 ); // Red
		row++;
		if ( scripts\sp\zom\kino_config::kinoEscalationValue() != 0 )
		{
			kinoActiveLine( "- " + level.kino_challenge_escalation.label + ": " +
				level.kino_challenge_escalation.options[level.kino_challenge_escalation.selected], row );
			row++;
		}
		for ( i = 0; i < level.kino_challenge_rules.size; i++ )
		{
			if ( level.kino_challenge_rules[i].enabled &&
				!scripts\sp\zom\kino_config::kinoRuleIsSuppressed( level.kino_challenge_rules[i].key ) )
			{
				label = level.kino_challenge_rules[i].label;
				kinoActiveLine( "- " + label, row );
				row++;
			}
		}
		for ( i = 0; i < level.kino_challenge_perks.size; i++ )
		{
			if ( level.kino_challenge_perks[i].enabled &&
				scripts\sp\zom\kino_config::kinoPerkRestrictionRelevant( level.kino_challenge_perks[i] ) )
			{
				kinoActiveLine( "- No " + level.kino_challenge_perks[i].label, row );
				row++;
			}
		}
	}
}

kinoMenuEntry( kind, label, index )
{
	entry = SpawnStruct();
	entry.kind = kind;
	entry.label = label;
	entry.index = index;
	return entry;
}

kinoMenuEntries( menu )
{
	entries = [];
	if ( menu.page == "categories" )
	{
		entries[0] = kinoMenuEntry( "category_boons", "Boons >", -1 );
		entries[1] = kinoMenuEntry( "category_curses", "Curses >", -1 );
		entries[2] = kinoMenuEntry( "start", "START GAME (locks settings)", -1 );
		if ( menu.confirming )
			entries[2].label = "START GAME? A confirm / B back";
		return entries;
	}
	if ( menu.page == "boons" )
	{
		for ( i = 0; i < level.kino_challenge_boons.size; i++ )
		{
			boon = level.kino_challenge_boons[i];
			entries[entries.size] = kinoMenuEntry( "boon", boon.label + ": " +
				scripts\sp\zom\kino_config::kinoBoonLabel( boon ), i );
		}
		entries[entries.size] = kinoMenuEntry( "playtest", "Playtest >", -1 );
		entries[entries.size] = kinoMenuEntry( "back_categories", "Back", -1 );
		return entries;
	}
	if ( menu.page == "playtest" )
	{
		for ( i = 0; i < level.kino_challenge_playtest.size; i++ )
		{
			option = level.kino_challenge_playtest[i];
			entries[entries.size] = kinoMenuEntry( "playtest_option", option.label + ": " +
				option.options[option.selected], i );
		}
		entries[entries.size] = kinoMenuEntry( "back_boons", "Back", -1 );
		return entries;
	}
	if ( menu.page == "perks" )
	{
		entries[entries.size] = kinoMenuEntry( "allow_perks", "Allow All", -1 );
		entries[entries.size] = kinoMenuEntry( "restrict_perks", "Restrict All", -1 );
		for ( i = 0; i < level.kino_challenge_perks.size; i++ )
		{
			perk = level.kino_challenge_perks[i];
			if ( !scripts\sp\zom\kino_config::kinoPerkRestrictionRelevant( perk ) )
				continue;
			state = "Allowed";
			if ( perk.enabled )
				state = "Restricted";
			if ( !perk.present )
				state = "Not on map";
			entries[entries.size] = kinoMenuEntry( "perk", perk.label + ": " + state, i );
		}
		entries[entries.size] = kinoMenuEntry( "back_main", "Back", -1 );
		return entries;
	}
	if ( scripts\sp\zom\kino_config::kinoHasRelevantPerks() )
	{
		entries[entries.size] = kinoMenuEntry( "perks", "Perks > (" +
			scripts\sp\zom\kino_config::kinoPerkCount() + " restricted)", -1 );
	}
	entries[entries.size] = kinoMenuEntry( "escalation", level.kino_challenge_escalation.label + ": " +
		level.kino_challenge_escalation.options[level.kino_challenge_escalation.selected], -1 );
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( scripts\sp\zom\kino_config::kinoRuleIsSuppressed( level.kino_challenge_rules[i].key ) )
			continue;
		state = "OFF";
		if ( level.kino_challenge_rules[i].enabled )
			state = "ON";
		entries[entries.size] = kinoMenuEntry( "rule", level.kino_challenge_rules[i].label + ": " + state, i );
	}
	entries[entries.size] = kinoMenuEntry( "random", "Random N Rules: " + level.kino_challenge_random_count, -1 );
	return entries;
}

kinoMenuRows( menu )
{
	entries = kinoMenuEntries( menu );
	rows = [];
	for ( i = 0; i < entries.size; i++ )
		rows[i] = entries[i].label;
	return rows;
}

kinoRefreshMenu( menu )
{
	footer = level.kino_challenge_hud[level.kino_challenge_hud.size - 1];
	title = "KINO CHALLENGES";
	if ( menu.page == "categories" )
		title = "CHALLENGE TYPE";
	else if ( menu.page == "boons" )
		title = "BOONS";
	else if ( menu.page == "playtest" )
		title = "PLAYTEST";
	else if ( menu.page == "perks" )
		title = "PERK RESTRICTIONS";
	level.kino_challenge_hud[0] SetText( title );
	rows = kinoMenuRows( menu );
	footer SetPoint( "TOPLEFT", "TOPLEFT", 14, 38 + rows.size * 17 );
	for ( i = 0; i < level.kino_challenge_menu_rows; i++ )
	{
		text = " ";
		if ( i < rows.size )
		{
			prefix = "  ";
			if ( i == menu.selected )
				prefix = "> ";
			text = prefix + rows[i];
		}
		level.kino_challenge_hud[i + 1] SetText( text );
	}
}

kinoMakeMenu()
{
	level.kino_challenge_hud = [];
	level.kino_challenge_menu_rows = level.kino_challenge_rules.size + 4;
	if ( level.kino_challenge_menu_rows < level.kino_challenge_perks.size + 3 )
		level.kino_challenge_menu_rows = level.kino_challenge_perks.size + 3;
	if ( level.kino_challenge_menu_rows < level.kino_challenge_boons.size + 2 )
		level.kino_challenge_menu_rows = level.kino_challenge_boons.size + 2;
	if ( level.kino_challenge_menu_rows < level.kino_challenge_playtest.size + 1 )
		level.kino_challenge_menu_rows = level.kino_challenge_playtest.size + 1;
	for ( i = 0; i <= level.kino_challenge_menu_rows; i++ )
	{
		hud = CreateServerFontString( "objective", 1.0 );
		hud.fontscale = 1.0;
		hud SetPoint( "TOPLEFT", "TOPLEFT", 14, 18 + i * 13 );
		level.kino_challenge_hud[i] = hud;
	}
	level.kino_challenge_hud[0].color = ( 0.25, 0.85, 1 );
	hud = CreateServerFontString( "objective", 1.0 );
	hud.fontscale = 1.0;
	hud SetPoint( "TOPLEFT", "TOPLEFT", 14, 38 + level.kino_challenge_menu_rows * 17 );
	hud SetText( "D-pad: move/change | A: select | B: back | Host only" );
	level.kino_challenge_hud[level.kino_challenge_hud.size] = hud;
}