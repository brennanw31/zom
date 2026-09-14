// Rule enforcement, boons, playtest options, and gameplay detours.
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_hud_util;
#include common_scripts\utility;
#include scripts\sp\zom\kino_config;

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
	switch ( scripts\sp\zom\kino_config::kinoBoonValue( "damage" ) )
	{
		case 1: return 1.1;
		case 2: return 1.2;
		case 3: return 1.5;
		case 4: return 2;
	}
	return 1;
}

kinoDisableTarget( targetname )
{
	triggers = GetEntArray( targetname, "targetname" );
	for ( i = 0; i < triggers.size; i++ )
		triggers[i] disable_trigger();
}

kinoDisableThunderGun()
{
	if ( IsDefined( level.zombie_weapons["thundergun_zm"] ) )
		level.zombie_weapons["thundergun_zm"].is_in_box = false;
	if ( IsDefined( level.zombie_include_weapons["thundergun_zm"] ) )
		level.zombie_include_weapons["thundergun_zm"] = false;
}

kinoApplySpawnRateCurse()
{
	level.zombie_vars["zombie_spawn_delay"] = 0.04;
}

kinoPlaytestStartingRound()
{
	switch ( scripts\sp\zom\kino_config::kinoPlaytestValue( "starting_round" ) )
	{
		case 1: return 10;
		case 2: return 20;
		case 3: return 50;
	}
	return 1;
}

kinoApplyPlaytestStartingRound()
{
	starting_round = kinoPlaytestStartingRound();
	if ( starting_round == 1 )
		return;
	level.first_round = false;
	level.round_number = starting_round;
	level.zombie_move_speed = starting_round * level.zombie_vars["zombie_move_speed_multiplier"];
	spawn_delay = level.zombie_vars["zombie_spawn_delay"];
	round_delay_scale = 0.95;
	minimum_spawn_delay = 0.08;
	for ( i = 1; i < starting_round; i++ )
	{
		spawn_delay *= round_delay_scale;
		if ( spawn_delay < minimum_spawn_delay )
		{
			spawn_delay = minimum_spawn_delay;
			break;
		}
	}
	level.zombie_vars["zombie_spawn_delay"] = spawn_delay;
}

kinoPlaytestWeapon()
{
	switch ( scripts\sp\zom\kino_config::kinoPlaytestValue( "weapon" ) )
	{
		case 1: return "hk21_upgraded_zm";
		case 2: return "ray_gun_upgraded_zm";
		case 3: return "thundergun_upgraded_zm";
	}
	return undefined;
}

kinoGivePlaytestPoints( player )
{
	if ( level.kino_boon_income_scale != 1 )
	{
		disableDetourOnce( level.kino_income_func );
		player [[level.kino_income_func]]( 100000 );
		return;
	}
	player maps\_zombiemode_score::add_to_player_score( 100000 );
}

kinoInfiniteAmmo()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		wait( 0.1 );
		weapon = self GetCurrentWeapon();
		if ( weapon != "none" )
			self GiveMaxAmmo( weapon );
		offhand = self GetCurrentOffhand();
		if ( offhand != "none" )
			self GiveMaxAmmo( offhand );
	}
}

kinoApplyPlaytest( player )
{
	if ( scripts\sp\zom\kino_config::kinoPlaytestValue( "god_mode" ) == 1 )
		player EnableInvulnerability();
	weapon = kinoPlaytestWeapon();
	if ( IsDefined( weapon ) )
		player GiveWeapon( weapon );
	if ( scripts\sp\zom\kino_config::kinoPlaytestValue( "points" ) == 1 )
		kinoGivePlaytestPoints( player );
	if ( scripts\sp\zom\kino_config::kinoPlaytestValue( "infinite_ammo" ) == 1 )
		player thread kinoInfiniteAmmo();
}

kinoApplyHordeSizeCurse()
{
	level.zombie_ai_limit = 30;
	SetAILimit( level.zombie_ai_limit );
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
		case "no_walkers":
			// set_run_speed() selects sprint when RandomIntRange(base, base+35) > 70.
			// Set the initial base AND the multiplier used at every round end.
			level.zombie_move_speed = 71;
			level.zombie_vars["zombie_move_speed_multiplier"] = 71;
			break;
		case "no_window_barricades": kinoDisableBarricades(); break;
		case "spawn_rate": kinoApplySpawnRateCurse(); break;
		case "horde_size": kinoApplyHordeSizeCurse(); break;
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
	switch ( scripts\sp\zom\kino_config::kinoBoonValue( "income" ) )
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
	}
	return "Normal";
}

kinoApplyCooldown()
{
	if ( level.kino_challenge_cooldown == 0 )
		return;
	level.kino_cooldown_scale = 0.2;
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