// Kino Challenge Configurator -- host/server extension for Plutonium T5.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;

init()
{
	if ( IsDefined( level.kino_challenges_loaded ) || level.script != "zombie_theater" )
		return;
	level.kino_challenges_loaded = true;
	level.kino_challenge_rules = [];
	level.kino_challenge_perks = [];
	level.kino_challenge_boons = [];
	level.kino_challenge_hud = [];
	level.kino_challenge_random_count = 0;
	level.kino_challenge_cooldown = 0;
	level.kino_challenge_menu_locked = false;
	kinoRegisterRules();
	kinoRegisterPerks();
	kinoRegisterBoons();
	level.round_prestart_func = ::kinoChallengePrestart;
}

kinoRegisterRules()
{
	kinoAddRule( "no_power", "No Power" );
	kinoAddRule( "no_pack_a_punch", "No Pack-a-Punch" );
	kinoAddRule( "no_mystery_box", "No Mystery Box" );
	kinoAddRule( "no_thunder_gun", "No Thunder Gun" );
	kinoAddRule( "starting_room_only", "Starting Room Only" );
	kinoAddRule( "wall_weapons_only", "Wall Weapons Only" );
	kinoAddRule( "no_walkers", "No Walkers" );
	kinoAddRule( "no_window_barricades", "No Window Barricades" );
}

kinoAddRule( key, label )
{
	rule = SpawnStruct();
	rule.key = key;
	rule.label = label;
	rule.enabled = false;
	level.kino_challenge_rules[level.kino_challenge_rules.size] = rule;
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
		if ( level.kino_challenge_perks[i].enabled )
			count++;
	}
	return count;
}

kinoBoonLabel( boon )
{
	return boon.options[boon.selected];
}

kinoBoonCycle( boon, step )
{
	boon.selected = kinoWrap( boon.selected + step, boon.options.size );
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

kinoDisableTarget( targetname )
{
	triggers = GetEntArray( targetname, "targetname" );
	for ( i = 0; i < triggers.size; i++ )
		triggers[i] disable_trigger();
}

kinoApplyPerks()
{
	triggers = GetEntArray( "zombie_vending", "targetname" );
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		perk = level.kino_challenge_perks[i];
		if ( !perk.enabled )
			continue;
		for ( j = 0; j < triggers.size; j++ )
		{
			if ( IsDefined( triggers[j].script_noteworthy ) &&
				( triggers[j].script_noteworthy == perk.key || triggers[j].script_noteworthy == perk.key + "_upgrade" ) )
				triggers[j] disable_trigger();
		}
	}
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

kinoActorDamage( weapon, damage, attacker )
{
	if ( IsDefined( self.kino_original_actor_damage_func ) )
		damage = self [[self.kino_original_actor_damage_func]]( weapon, damage, attacker );
	if ( IsDefined( attacker ) && IsPlayer( attacker ) )
		damage = int( damage * level.kino_boon_damage_scale );
	return damage;
}

kinoApplyDamageToZombie()
{
	if ( IsDefined( self.kino_original_actor_damage_func ) )
		return;
	self.kino_original_actor_damage_func = self.actor_damage_func;
	self.actor_damage_func = ::kinoActorDamage;
}

kinoApplyDamageBoon()
{
	if ( !IsDefined( level._zombie_custom_spawn_logic ) )
		level._zombie_custom_spawn_logic = [];
	else if ( !IsArray( level._zombie_custom_spawn_logic ) )
	{
		original_spawn_logic = level._zombie_custom_spawn_logic;
		level._zombie_custom_spawn_logic = [];
		level._zombie_custom_spawn_logic[0] = original_spawn_logic;
	}
	level._zombie_custom_spawn_logic[level._zombie_custom_spawn_logic.size] = ::kinoApplyDamageToZombie;
	zombies = GetAiSpeciesArray( "axis", "all" );
	for ( i = 0; i < zombies.size; i++ )
		zombies[i] kinoApplyDamageToZombie();
}

kinoDamageScale()
{
	switch ( kinoBoonValue( "damage" ) )
	{
		case 1: return 1.1;
		case 2: return 1.2;
		case 3: return 1.5;
		case 4: return 2;
	}
	return 1;
}

kinoDisableThunderGun()
{
	if ( IsDefined( level.zombie_weapons["thundergun_zm"] ) )
		level.zombie_weapons["thundergun_zm"].is_in_box = false;
	if ( IsDefined( level.zombie_include_weapons["thundergun_zm"] ) )
		level.zombie_include_weapons["thundergun_zm"] = false;
}

kinoApplyRule( key )
{
	switch ( key )
	{
		case "no_power": kinoDisableTarget( "use_elec_switch" ); break;
		case "no_pack_a_punch": kinoDisableTarget( "zombie_vending_upgrade" ); break;
		case "no_mystery_box": kinoDisableTarget( "treasure_chest_use" ); break;
		case "no_thunder_gun": kinoDisableThunderGun(); break;
		case "starting_room_only":
			kinoDisableTarget( "zombie_door" );
			kinoDisableTarget( "zombie_debris" );
			break;
		case "wall_weapons_only": kinoDisableTarget( "treasure_chest_use" ); break;
		case "no_walkers":
			// set_run_speed() selects sprint when RandomIntRange(base, base+35) > 70.
			// Set the initial base AND the multiplier used at every round end.
			level.zombie_move_speed = 71;
			level.zombie_vars["zombie_move_speed_multiplier"] = 71;
			break;
		case "no_window_barricades": kinoDisableBarricades(); break;
	}
}

kinoDisableBarricades()
{
	replaceFunc( getFunction( "maps/_zombiemode_utility", "no_valid_repairable_boards" ), ::kinoNoRepairableBoards );
	level.kino_specific_drop = getFunction( "maps/_zombiemode_powerups", "specific_powerup_drop" );
	replaceFunc( level.kino_specific_drop, ::kinoSpecificPowerupDrop );
	filtered = [];
	for ( i = 0; i < level.zombie_powerup_array.size; i++ )
	{
		if ( level.zombie_powerup_array[i] != "carpenter" )
			filtered[filtered.size] = level.zombie_powerup_array[i];
	}
	level.zombie_powerup_array = filtered;
	level.zombie_powerup_index = 0;
	if ( IsDefined( level.zombie_include_powerups ) )
		level.zombie_include_powerups["carpenter"] = undefined;
	for ( i = 0; i < level.exterior_goals.size; i++ )
	{
		node = level.exterior_goals[i];
		if ( !IsDefined( node.barrier_chunks ) )
			continue;
		for ( j = 0; j < node.barrier_chunks.size; j++ )
		{
			chunk = node.barrier_chunks[j];
			chunk.state = "destroyed";
			chunk.destroyed = true;
			chunk Hide();
			chunk notSolid();
		}
		if ( IsDefined( node.clip ) )
		{
			node.clip ConnectPaths();
			node.clip disable_trigger();
		}
	}
}

kinoNoRepairableBoards( barrier_chunks )
{
	return true;
}

kinoSpecificPowerupDrop( powerup_name, drop_spot )
{
	if ( powerup_name == "carpenter" )
		return;
	disableDetourOnce( level.kino_specific_drop );
	self [[level.kino_specific_drop]]( powerup_name, drop_spot );
}

kinoApplyPlayerBoons( player )
{
	health_target = 100 + level.kino_boon_health_bonus;
	player SetMaxHealth( health_target );
	player.health = health_target;
	player setMoveSpeedScale( level.kino_boon_movement_scale );
	if ( level.kino_boon_unlimited_sprint )
	{
		player SetClientDvar( "player_sprintUnlimited", "1" );
		player SetClientDvar( "player_sprintTime", "999999" );
	}
}

kinoApplyHealthBoon()
{
	health_target = 100 + level.kino_boon_health_bonus;
	if ( self HasPerk( "specialty_armorvest" ) )
		health_target = level.zombie_vars["zombie_perk_juggernaut_health"] + level.kino_boon_health_bonus;
	else if ( self HasPerk( "specialty_armorvest_upgrade" ) )
		health_target = level.zombie_vars["zombie_perk_juggernaut_health_upgrade"] + level.kino_boon_health_bonus;
	self SetMaxHealth( health_target );
	self.health = health_target;
}

kinoGivePerk( perk, bought )
{
	disableDetourOnce( level.kino_give_perk_func );
	self [[level.kino_give_perk_func]]( perk, bought );
	if ( perk == "specialty_armorvest" || perk == "specialty_armorvest_upgrade" )
		self kinoApplyHealthBoon();
}

kinoApplyHealthBoonHook()
{
	if ( level.kino_boon_health_bonus <= 0 )
		return;
	level.kino_give_perk_func = getFunction( "maps/_zombiemode_perks", "give_perk" );
	replaceFunc( level.kino_give_perk_func, ::kinoGivePerk );
}

kinoApplySelectedRules()
{
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( level.kino_challenge_rules[i].enabled )
			kinoApplyRule( level.kino_challenge_rules[i].key );
	}
}

kinoIncomeScale()
{
	switch ( kinoBoonValue( "income" ) )
	{
		case 1: return 1.1;
		case 2: return 1.2;
		case 3: return 1.5;
		case 4: return 2;
	}
	return 1;
}

kinoAddPlayerScore( points, add_to_total )
{
	if ( !IsDefined( points ) )
		return;
	points = int( points * level.kino_boon_income_scale + 0.5 );
	disableDetourOnce( level.kino_income_func );
	self [[level.kino_income_func]]( points, add_to_total );
}

kinoApplyIncomeBoon()
{
	if ( level.kino_boon_income_scale == 1 )
		return;
	level.kino_income_func = getFunction( "maps/_zombiemode_score", "add_to_player_score" );
	replaceFunc( level.kino_income_func, ::kinoAddPlayerScore );
}

kinoCooldownLabel()
{
	switch ( level.kino_challenge_cooldown )
	{
		case 1: return "Short";
		case 2: return "None";
	}
	return "Normal";
}

kinoApplyCooldown()
{
	if ( level.kino_challenge_cooldown == 0 )
		return;
	level.kino_cooldown_scale = 0.5;
	if ( level.kino_challenge_cooldown == 2 )
		level.kino_cooldown_scale = 0;
	level.kino_chalk_one_up = getFunction( "maps/_zombiemode", "chalk_one_up" );
	replaceFunc( level.kino_chalk_one_up, ::kinoChalkOneUp );
	replaceFunc( getFunction( "maps/_zombiemode", "chalk_round_over" ), ::kinoChalkRoundOver );
}

kinoChalkRoundOver()
{
	time = level.zombie_vars["zombie_between_round_time"];
	if ( time > 3 )
		time -= 2;
	pulses = 0;
	for ( q = 0; q < time * 0.5; q++ )
		pulses++;
	delay = ( pulses + 2 ) * level.kino_cooldown_scale;
	if ( level.round_number <= 5 || level.round_number > 10 )
		level.chalk_hud2 SetText( " " );
	if ( delay > 0 )
		wait( delay );
	level.chalk_hud1.alpha = 0;
	level.chalk_hud2.alpha = 0;
}

kinoChalkOneUp()
{
	if ( level.first_round )
	{
		disableDetourOnce( level.kino_chalk_one_up );
		self [[level.kino_chalk_one_up]]();
		return;
	}
	delay = 2.5 * level.kino_cooldown_scale;
	if ( delay > 0 )
		wait( delay );
	hud1 = level.chalk_hud1;
	hud2 = level.chalk_hud2;
	if ( level.round_number <= 5 )
	{
		hud1 SetShader( "hud_chalk_" + level.round_number, 64, 64 );
		hud2 SetText( " " );
	}
	else if ( level.round_number <= 10 )
	{
		hud1 SetShader( "hud_chalk_5", 64, 64 );
		hud2 SetShader( "hud_chalk_" + ( level.round_number - 5 ), 64, 64 );
	}
	else
	{
		hud1.fontscale = 32;
		hud1 SetValue( level.round_number );
		hud2 SetText( " " );
	}
	if ( IsDefined( level.chalk_override ) )
	{
		hud1 SetText( level.chalk_override );
		hud2 SetText( " " );
		level.chalk_override = undefined;
	}
	hud1.alpha = 1;
	hud2.alpha = 1;
	hud1.color = ( 0.21, 0, 0 );
	hud2.color = ( 0.21, 0, 0 );
	if ( !IsDefined( level.doground_nomusic ) )
		level.doground_nomusic = 0;
	if ( level.round_number == 5 || level.round_number == 10 || level.round_number == 20 ||
		level.round_number == 35 || level.round_number == 50 )
	{
		players = get_players();
		if ( players.size > 0 )
			players[RandomInt( players.size )] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "round_" + level.round_number );
	}
	ReportMTU( level.round_number );
}

kinoLockRules()
{
	if ( level.kino_challenge_menu_locked )
		return;
	if ( level.kino_challenge_random_count > 0 )
		kinoChooseRandomRules();
	level.kino_challenge_menu_locked = true;
	kinoApplyPerks();
	level.kino_boon_health_bonus = kinoBoonValue( "health" ) * 50;
	level.kino_boon_damage_scale = kinoDamageScale();
	level.kino_boon_movement_scale = 1 + kinoBoonValue( "movement" ) * 0.05;
	level.kino_boon_unlimited_sprint = kinoBoonValue( "sprint" ) == 1;
	level.kino_boon_income_scale = kinoIncomeScale();
	kinoApplyIncomeBoon();
	kinoApplyHealthBoonHook();
	players = get_players();
	for ( i = 0; i < players.size; i++ )
		kinoApplyPlayerBoons( players[i] );
	if ( kinoBoonValue( "damage" ) > 0 )
		kinoApplyDamageBoon();
	kinoApplySelectedRules();
	kinoApplyCooldown();
	for ( i = 0; i < level.kino_challenge_hud.size; i++ )
		level.kino_challenge_hud[i] destroyElem();
	kinoShowLockedRules();
}

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
	hud = kinoActiveLine( "GAME RULES", 0 );
	hud.color = ( 0.25, 0.85, 1 );
	row = 1;
	hud = kinoActiveLine( "BOONS", row );
	hud.color = ( 0.25, 0.85, 0.25 );
	row++;
	has_selection = false;
	for ( i = 0; i < level.kino_challenge_boons.size; i++ )
	{
		if ( level.kino_challenge_boons[i].selected != 0 )
		{
			kinoActiveLine( "+ " + level.kino_challenge_boons[i].label + ": " + kinoBoonLabel( level.kino_challenge_boons[i] ), row );
			row++;
			has_selection = true;
		}
	}
	hud = kinoActiveLine( "CURSES", row );
	hud.color = ( 0.85, 0.25, 0.25 );
	row++;
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		if ( level.kino_challenge_rules[i].enabled )
		{
			kinoActiveLine( "- " + level.kino_challenge_rules[i].label, row );
			row++;
			has_selection = true;
		}
	}
	for ( i = 0; i < level.kino_challenge_perks.size; i++ )
	{
		if ( level.kino_challenge_perks[i].enabled )
		{
			kinoActiveLine( "- No " + level.kino_challenge_perks[i].label, row );
			row++;
			has_selection = true;
		}
	}
	if ( level.kino_challenge_cooldown != 0 )
	{
		kinoActiveLine( "- Round Cooldown: " + kinoCooldownLabel(), row );
		row++;
		has_selection = true;
	}
	if ( !has_selection )
		kinoActiveLine( "- No restrictions", row );
}

kinoMenuRows( menu )
{
	rows = [];
	if ( menu.page == "categories" )
	{
		rows[0] = "Boons >";
		rows[1] = "Curses >";
		return rows;
	}
	if ( menu.page == "boons" )
	{
		for ( i = 0; i < level.kino_challenge_boons.size; i++ )
		{
			boon = level.kino_challenge_boons[i];
			rows[rows.size] = boon.label + ": " + kinoBoonLabel( boon );
		}
		rows[rows.size] = "Back";
		return rows;
	}
	if ( menu.page == "perks" )
	{
		rows[0] = "Allow All";
		rows[1] = "Restrict All";
		for ( i = 0; i < level.kino_challenge_perks.size; i++ )
		{
			perk = level.kino_challenge_perks[i];
			state = "Allowed";
			if ( perk.enabled )
				state = "Restricted";
			if ( !perk.present )
				state = "Not on map";
			rows[rows.size] = perk.label + ": " + state;
		}
		rows[rows.size] = "Back";
		return rows;
	}
	rows[0] = "Perks > (" + kinoPerkCount() + " restricted)";
	for ( i = 0; i < level.kino_challenge_rules.size; i++ )
	{
		state = "OFF";
		if ( level.kino_challenge_rules[i].enabled )
			state = "ON";
		rows[rows.size] = level.kino_challenge_rules[i].label + ": " + state;
	}
	rows[rows.size] = "Round Cooldown: " + kinoCooldownLabel();
	rows[rows.size] = "Random N Rules: " + level.kino_challenge_random_count;
	rows[rows.size] = "START GAME (locks settings)";
	if ( menu.confirming )
		rows[rows.size - 1] = "START GAME? A confirm / B back";
	return rows;
}

kinoRefreshMenu( menu )
{
	title = "KINO CHALLENGES";
	if ( menu.page == "categories" )
		title = "CHALLENGE TYPE";
	else if ( menu.page == "boons" )
		title = "BOONS";
	else if ( menu.page == "perks" )
		title = "PERK RESTRICTIONS";
	level.kino_challenge_hud[0] SetText( title );
	rows = kinoMenuRows( menu );
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
	if ( level.kino_challenge_menu_rows < level.kino_challenge_boons.size + 1 )
		level.kino_challenge_menu_rows = level.kino_challenge_boons.size + 1;
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
		if ( menu.page == "boons" || menu.page == "main" )
			menu.page = "categories";
		else
			menu.page = "main";
		menu.selected = 0;
		return;
	}
	rows = kinoMenuRows( menu );
	if ( input == "kino_next" || input == "kino_previous" )
	{
		step = 1;
		if ( input == "kino_previous" )
			step = -1;
		menu.selected = kinoWrap( menu.selected + step, rows.size );
		return;
	}
	if ( input != "kino_select" && input != "kino_decrease" && input != "kino_increase" )
		return;
	if ( menu.page == "categories" )
	{
		if ( input == "kino_select" || input == "kino_increase" )
		{
			if ( menu.selected == 0 )
				menu.page = "boons";
			else
				menu.page = "main";
			menu.selected = 0;
		}
		return;
	}
	if ( menu.page == "boons" )
	{
		if ( menu.selected == rows.size - 1 && input == "kino_select" )
		{
			menu.page = "categories";
			menu.selected = 0;
		}
		else if ( menu.selected < rows.size - 1 )
		{
			boon = level.kino_challenge_boons[menu.selected];
			step = 1;
			if ( input == "kino_decrease" )
				step = -1;
			kinoBoonCycle( boon, step );
		}
		return;
	}
	if ( menu.page == "perks" )
	{
		if ( menu.selected == 0 && input == "kino_select" )
			kinoSetAllPerks( false );
		else if ( menu.selected == 1 && input == "kino_select" )
			kinoSetAllPerks( true );
		else if ( menu.selected == rows.size - 1 && input == "kino_select" )
		{
			menu.page = "main";
			menu.selected = 0;
		}
		else if ( menu.selected >= 2 && menu.selected < rows.size - 1 )
		{
			perk = level.kino_challenge_perks[menu.selected - 2];
			if ( perk.present )
				kinoToggle( perk, input );
		}
		return;
	}
	if ( menu.selected == 0 )
	{
		if ( input == "kino_select" || input == "kino_increase" )
		{
			menu.page = "perks";
			menu.selected = 0;
		}
		return;
	}
	if ( menu.selected <= level.kino_challenge_rules.size )
	{
		kinoToggle( level.kino_challenge_rules[menu.selected - 1], input );
		return;
	}
	step = 1;
	if ( input == "kino_decrease" )
		step = -1;
	if ( menu.selected == level.kino_challenge_rules.size + 1 )
		level.kino_challenge_cooldown = kinoWrap( level.kino_challenge_cooldown + step, 3 );
	else if ( menu.selected == level.kino_challenge_rules.size + 2 )
	{
		pool = kinoRandomPool();
		level.kino_challenge_random_count = kinoWrap( level.kino_challenge_random_count + step, pool.size + 1 );
	}
	else if ( input == "kino_select" )
		menu.confirming = true;
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
		kinoRefreshMenu( menu );
		input = host waittill_any_return( "kino_next", "kino_previous", "kino_select", "kino_decrease", "kino_increase", "kino_back" );
		kinoHandleInput( menu, input );
	}
}

kinoChallengePrestart()
{
	if ( level.kino_challenge_menu_locked )
		return;
	kinoFindPerks();
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
