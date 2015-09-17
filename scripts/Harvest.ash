/***********************************************\
					Harvest
	
    Written by Banana Lord with much help from
			the KoL Mafia community

\***********************************************/

script "Harvest.ash";
notify Banana Lord;
import <EatDrink.ash>;
import <canadv.ash>;
import <OCD Inventory Control.ash>;
import <volcano_mining.ash>;

check_version("Harvest", "Harvest", "2.0.9", 7015);

/*************\
  Global Maps
\*************/
string [effect] buffs_wanted;
int [string, effect] buffbot_data;
string [string] effects_to_remove;
int [item] my_hats;

record { 
	int meat_made; 
	int advs_spent; 
}	[string] statistics;

record { 
	string action; 
	int q; 
	string info; 
	string message; 
}	[item] temp_ocd;

// Load maps that are used by more than one function
file_to_map("HAR_Buffbot_Info.txt", buffbot_data);
file_to_map("HAR_Buffbot_Buffs.txt", buffs_wanted);


/**********************\
 Settings and Variables 
\**********************/
// General
boolean DOSEMIRARES = vars["har_gen_dosemirares"].to_boolean();
string CONSUME_SCRIPT = vars["har_gen_consume_script"];
string DEMON = vars["har_gen_demon_to_summon"];
string FRIAR_BLESSING = vars["har_gen_friar_blessing"];
effect CONCERT_EFFECT = vars["har_gen_concert_effect"].to_effect();
string POOL_STYLE = vars["har_gen_pool_style"];
string CCS = vars["har_gen_ccs"];
string BBS = vars["har_gen_bbs"];
boolean COMPLETED_SETUP = vars["har_gen_completed_setup"].to_boolean();
boolean DEFAULT_OCDDATA = vars["har_gen_defaultocd"].to_boolean();
boolean USE_SHIELDS = vars["har_gen_sugarshields"].to_boolean();
int OVERALL_BUDGET = vars["har_gen_budget"].to_int();
effect HATTER_BUFF = vars["har_gen_hatter_buff"].to_effect();
string PRECONSUMPTION_SCRIPT = vars["har_gen_preconsumption_script"];
string POSTCONSUMPTION_SCRIPT = vars["har_gen_postconsumption_script"];
string FINISH_UP_SCRIPT = vars["har_gen_finish_up_script"];
boolean BUY_RECORDINGS = vars["har_gen_buy_recordings"].to_boolean();
int VERBOSITY = vars["har_gen_verbosity"].to_int();
boolean OVERDRINK = vars["har_gen_overdrink"].to_boolean();

// Puttyfarming
boolean PUTTYFARM = vars["har_puttyfarm"].to_boolean();
string PUTTYFARMING_OUTFIT = vars["har_puttyfarming_outfit"];
familiar PUTTYFARMING_FAM = vars["har_puttyfarming_fam"].to_familiar();
item PUTTYFARMING_FAMEQUIP = vars["har_puttyfarming_famequip"].to_item();
string PUTTYFARMING_MOOD = vars["har_puttyfarming_mood"];

// Bountyhunting
boolean BOUNTYHUNT_EASY = vars["har_bountyhunt_easy"].to_boolean();
boolean BOUNTYHUNT_HARD = vars["har_bountyhunt_hard"].to_boolean();
boolean BOUNTYHUNT_SPECIAL = vars["har_bountyhunt_special"].to_boolean();
boolean BOUNTYHUNT = BOUNTYHUNT_EASY || BOUNTYHUNT_HARD || BOUNTYHUNT_SPECIAL;
string BOUNTYHUNTING_OUTFIT = vars["har_bountyhunting_outfit"];
familiar BOUNTYHUNTING_FAM = vars["har_bountyhunting_fam"].to_familiar();
item BOUNTYHUNTING_FAMEQUIP = vars["har_bountyhunting_famequip"].to_item();
string BOUNTYHUNTING_MOOD = vars["har_bountyhunting_mood"];
boolean BOUNTYHUNT_WITH_PUTTY = vars["har_bountyhunting_putty"].to_boolean();

// Duck hunting
boolean DUCKHUNT = vars["har_duckhunt"].to_boolean();
string DUCKHUNTING_OUTFIT = vars["har_duckhunting_outfit"];
familiar DUCKHUNTING_FAM = vars["har_duckhunting_fam"].to_familiar();
item DUCKHUNTING_FAMEQUIP = vars["har_duckhunting_famequip"].to_item();
string DUCKHUNTING_MOOD = vars["har_duckhunting_mood"];

// Volcano Mining
boolean VMINE = vars["har_vmine"].to_boolean();
string VMINING_OUTFIT = vars["har_vmining_outfit"];
int VMINING_ADVENTURE_LIMIT = vars["har_vmining_adventure_limit"].to_int();
boolean VMINING_MINE_VELVET = vars["har_vmining_mine_velvet"].to_boolean();
boolean VMINING_AUTO_DETECTION = vars["har_vmining_auto_detection"].to_boolean();

// Farming
boolean FARM = vars["har_farm"].to_boolean();
item SEA_HAT = vars["har_farming_sea_hat"].to_item();
string FARMING_OUTFIT = vars["har_farming_outfit"];
familiar FARMING_FAM = vars["har_farming_fam"].to_familiar();
item FARMING_FAMEQUIP = vars["har_farming_famequip"].to_item();
location FARMING_LOCATION = vars["har_farming_location"].to_location();
string FARMING_MOOD = vars["har_farming_mood"];
boolean PUTTY_OLFACTED = vars["har_farming_putty_olfacted"].to_boolean();
monster MONSTER_TO_SNIFF = vars["har_farming_olfacted_monster"].to_monster();
boolean DANCE_COMBOS = vars["har_farming_disco_combos"].to_boolean();

// Rollover
string ROLLOVER_OUTFIT = vars["har_rollover_outfit"];

// EatDrink
SIM_CONSUME = false;

// Other
int cookie_room;



/*****************\
 General Functions 
\*****************/
void announce(int verbosity_level, string message, boolean header) {
	/* Prints <message> if the user's verbosity setting is greater than or equal to 
	<verbosity_level>. Red = error, blue = normal info, purple = function name, 
	olive = internal function info. If the optional parameter <header> is true prints a 
	line across the mafia gCLI under the message. */
	
	string colour;
	switch (verbosity_level)
		{
		case -1:
			colour = "red";
			break;
		case 1:
			colour = "blue";
			break;
		case 2:
			colour = "purple";
			break;
		case 3:
			colour = "olive";
			break;
		}
	
	if(verbosity_level <=  VERBOSITY) {
		if(header)
			print("");
		print(message, colour);
		if(header)	
			print_html("<hr>");
		}
	}
	
void announce(int verbosity_level, string message) {
	/* Overloader for the three parameter version */
	announce(verbosity_level, message, false);
	}

void apply_prerun_settings() {
	/* Puts all settings back to the way they were before Harvest was called */
	announce(2, "apply_prerun_settings");
	
	set_property("currentMood", get_property("har_prerun_mood"));
	set_property("customCombatScript", get_property("har_prerun_ccs"));
	set_property("battleAction", get_property("har_prerun_battleaction"));
	set_property("betweenBattleScript", get_property("har_prerun_bbs"));
	set_property("counterScript", get_property("har_prerun_counterscript"));
	set_auto_attack(get_property("har_prerun_autoattack").to_int());
	}

void failure(string message) {
	/* Aborts cleanly by restoring all settings to the way they were before Harvest was called */
	
	apply_prerun_settings();
	abort(message);
	}

boolean have_foldable(string foldable) {
	/* Returns true if you have any of the forms of the foldable related to <foldable>.
	"Putty" for spooky putty, "cheese" for stinky cheese, "origami" for naughty origami, 
	"doh" for Rain-Doh. */
	announce(2, "have_foldable");

	int count;
	switch (foldable) {
		case "putty":
			foreach putty_form in get_related($item[Spooky Putty sheet], "fold")
				if(available_amount(putty_form) > 0)
					count += available_amount(putty_form);
			break;
		case "cheese":
			foreach cheese_form in get_related($item[stinky cheese eye], "fold")
				if(available_amount(cheese_form) > 0)
					count += available_amount(cheese_form);
			break;
		case "origami":
			foreach origami_form in get_related($item[origami pasties], "fold")
				if(available_amount(origami_form) > 0)
					count += available_amount(origami_form);
			break;
		case "doh":
			int doh_count = available_amount($item[Rain-Doh black box]) + available_amount($item[Rain-Doh box full of monster]);
			if(doh_count > 0)
				count += doh_count;
			break;
		}

	return count > 0;
	}
	
boolean get_foldable(item goal) {
	/*	Attempts to get a given form of a foldable by first retrieving it from your closet 
	or display case and then folding it into the desired form */
	announce(2, "get_foldable");
	
	boolean look_get(item it, boolean DC) { 
		if(DC)
			return(display_amount(it) > 0 && take_display(1, it)); 
		
		return(available_amount(it) > 0 && retrieve_item(1, it)); 
		} 
	
	if(item_amount(goal) == 0 && !have_equipped(goal)) {
		foreach DC in $booleans[false, true] { 
			if(look_get(goal, DC))
				return true;
				
			foreach form in get_related(goal, "fold") { 
				if(look_get(form, DC)) { 
					cli_execute("fold " + goal); 
					if(item_amount(goal) > 0)
						return true; 
					} 
				} 
			}
		}
	
	return item_amount(goal) > 0; 
	}
	
int total_copies() {
	/* Returns the number of putty + raindoh copies you can make in a day */
	announce(2, "total_copies");
	
	if (have_foldable("putty") && have_foldable("doh"))
		return 6;
		
	return 5;
}

int copies_available() {
	/* Returns the number of monster copies from putty/doh you have left for today */
	announce(2, "copies_available");
	
	return total_copies() - get_property("spookyPuttyCopiesMade").to_int() - get_property("_raindohCopiesMade").to_int();
}

boolean have_copied_monster() {
	/* Returns true if you have a monster trapped in putty/doh in your inventory */
	announce(2, "have_copied_monster");
	
	return item_amount($item[Spooky Putty monster]) + item_amount($item[Rain-Doh box full of monster]) > 0;
}

boolean have_monster_copier() {
	/* Returns true if you have something to copy a monster with */
	announce(2, "have_monster_copier");
	
	return item_amount($item[Spooky Putty sheet]) + item_amount($item[Rain-Doh black box]) > 0;
	}
	
int total_amount(item it) {
	/* Returns the total number you have of an item in all sections of your account */
	announce(2, "total_amount");
	
	return closet_amount(it)+display_amount(it)+item_amount(it)+storage_amount(it)+equipped_amount(it);
	}
	
int av_advs_per_day() {
	/*	Estimates the average number of adventures spent farming per day based on the last 
	7 days of data. If no data is available, returns 200 */
	
	file_to_map("HAR_Daily_Profit_"+my_name()+".txt", statistics);
	
	int days = count(statistics);
	int count;
	int weekly_turns_spent;
	int time_period = min(7, days);
	
	if(days == 0)
		return 200;
	
	foreach day in statistics {
		count += 1;
		
		if(count > days-time_period)
			weekly_turns_spent += max(0, statistics[day].advs_spent);
		}
		
	return round(weekly_turns_spent/time_period);
	}

boolean sr_counter_active() {
	/* Returns true if you have an active semirare counter */
	announce(2, "sr_counter_active");
	
	return get_counters("fortune", 0, 300).contains_text("Fortune Cookie");
	}

int num_srs() {
	/* Returns an estimate of the number of SRs you'll get today */
	announce(2, "num_srs");
	
	int smallest;
	int sr_gap = 180;
	int advs = av_advs_per_day();
	int num_srs;
	
	string txt = get_property("relayCounters");
	matcher puller = create_matcher("(\\d+):Fortune Cookie:fortune.gif", txt);
	if(puller.find()) 
		smallest = to_int(puller.group(1))-my_turncount();
	
	// If you don't have an active SR counter, your next SR could be in up to <sr_gap> turns
	if(!sr_counter_active())
		advs -= sr_gap;
	
	advs -= smallest;
	if(advs > 0)
		num_srs += 1 + max(0, advs/sr_gap);
		
	return(num_srs);
	}
	
void closet_meat() {
	/* Closets all of your meat except the amount specified for Harvest's budget in your vars file */
	announce(2, "closet_meat");
	
	if(OVERALL_BUDGET >= 0)
		put_closet(max(0, my_meat() - OVERALL_BUDGET));
	}
	
string current_activity() {
	/* Returns your current activity */
	announce(2, "current_activity");
	
	return get_property("har_current_activity");
	}
	
boolean finished_farming() {
	/* Returns true if you have finished farming for the day, or false if you are still 
	able to farm */
	announce(2, "finished_farming");
	
	boolean result;
	if(my_inebriety() > inebriety_limit())
		result = true;
	else if (my_fullness() < fullness_limit()-cookie_room || my_inebriety() < inebriety_limit() || my_spleen_use() < spleen_limit())
			result = false;
	else if (my_adventures() > 0)
		result = false;
	else
		result = true;	
	
	announce(3, result);
	
	return result;
	}

boolean file_empty(string file) {
	/*	Returns true if the specified file contains nothing
		Only works for maps of the form -> string [string] map_name */
	announce(2, "file_empty");
	
	string [string] test_map;
	file_to_map(file, test_map);

	return count(test_map) == 0;
	}

item hatter_hat(int chars_needed) {
	/* Returns a hat from your inventory with the requested number of characters in its 
	name or none if you do not have such a hat */
	announce(2, "hatter_hat");

	foreach it in $items[]
		if(item_type(it) == "hat" && available_amount(it) > 0 && length(replace_string(it, " ", "")) == chars_needed)
			return it;
			
	return $item[none];
	}
	
boolean is_underwater(location loc) {
	/* Returns true if the specified location is under the sea */
	announce(2, "is_underwater");
	
	return loc.zone == "The Sea";
	}
	
int num_ducks() {
	/* Returns the number of ducks you can fight each day */
	announce(2, "num_ducks");
		
	switch (get_property("sidequestFarmCompleted")) {
		case "fratboy":
			return 15;
		case "hippy":
			return 10;
		default:
			return 5;
		}
	}
	

/**************\
 Initialisation 
\**************/
void update_profit_datafile()
	{
	/*	Updates Har_Daily_Profit.txt to the data structure implemented in Harvest v2 if the user is
		updating from an earlier version. Uses an estimated value for advs_spent based on turns per 
		day this ascension for days for which this value has not been recorded */
	announce(2, "update_profit_datafile");
	
	if(!get_property("har_profit_updated").to_boolean())
		{
		int [string] old_daily_profit;
		file_to_map("HAR_Daily_Profit_"+my_name()+".txt", old_daily_profit);
		map_to_file(old_daily_profit, "HAR_Old_Daily_Profit_"+my_name()+".txt"); // Make a backup copy, just in case
		int approx_turns_per_day = max(150, round(my_turncount()/my_daycount()));
		
		foreach day in old_daily_profit
			{
			int old_meat = old_daily_profit[day];
			statistics[day].meat_made = old_meat;
			statistics[day].advs_spent = approx_turns_per_day;
			}
		
		map_to_file(statistics, "HAR_Daily_Profit_"+my_name()+".txt");
		set_property("har_profit_updated", true);
		announce(3, "Profit file updated");
		}
	else
		announce(3, "Profit file already updated");
	}

// Set default options
void set_general_options()
	{
	announce(2, "set_general_options");
	
	setvar("har_gen_verbosity", 1);
	setvar("har_gen_completed_setup", false);
	setvar("har_gen_ccs", "");
	setvar("har_gen_bbs", "");
	setvar("har_gen_dosemirares", false); // Default to false because user might not have CounterChecker.ash
	if(get_property("demonName2") != "")
		setvar("har_gen_demon_to_summon", "preternatural greed");
	else
		setvar("har_gen_demon_to_summon", "none");
	setvar("har_gen_friar_blessing", "familiar");
	if(item_amount($item[Clan VIP Lounge key]) > 0)
		setvar("har_gen_pool_style", "aggressive");
	else
		setvar("har_gen_pool_style", "none");
	if(hatter_hat(22) != $item[none])
		setvar("har_gen_hatter_buff", "Dances with Tweedles");
	else if(hatter_hat(28) != $item[none])
		setvar("har_gen_hatter_buff", "Quadrilled");
	else
		setvar("har_gen_hatter_buff", "none");
	setvar("har_gen_concert_effect", $effect[none]);
	setvar("har_gen_consume_script", "EatDrink.ash");
	setvar("har_gen_defaultocd", true);
	setvar("har_gen_sugarshields", true);
	setvar("har_gen_budget", 100000);
	setvar("har_gen_preconsumption_script", "");
	setvar("har_gen_postconsumption_script", "");
	setvar("har_gen_finish_up_script", "");
	setvar("har_gen_buy_recordings", false);
	setvar("har_gen_overdrink", true);
	}

void set_puttyfarming_options()	
	{
	announce(2, "set_puttyfarming_options");
	
	setvar("har_puttyfarm", false);
	setvar("har_puttyfarming_outfit", "");
	setvar("har_puttyfarming_mood", "");
	setvar("har_puttyfarming_fam", $familiar[none]);
	setvar("har_puttyfarming_famequip", $item[none]);
	}

void set_bountyhunting_options()
	{
	announce(2, "set_bountyhunting_options");
	
	setvar("har_bountyhunt_easy", false);
	setvar("har_bountyhunt_hard", false);
	setvar("har_bountyhunt_special", false);
	setvar("har_bountyhunting_outfit", "");
	setvar("har_bountyhunting_mood", "");
	setvar("har_bountyhunting_fam", $familiar[none]);
	setvar("har_bountyhunting_famequip", $item[none]);
	setvar("har_bountyhunting_putty", have_foldable("putty") || have_foldable("doh"));
	}
	
void set_duckhunting_options()
	{
	announce(2, "set_duckhunting_options");
	
	setvar("har_duckhunt", false);
	setvar("har_duckhunting_outfit", "");
	setvar("har_duckhunting_mood", "");
	setvar("har_duckhunting_fam", $familiar[none]);
	setvar("har_duckhunting_famequip", $item[none]);
	setvar("har_duckhunting_putty", have_foldable("putty") || have_foldable("doh"));
	}

void set_vmining_options()
	{
	announce(2, "set_vmining_options");

	setvar("har_vmine", false);
	setvar("har_vmining_outfit", "");
	setvar("har_vmining_adventure_limit", 0);
	setvar("har_vmining_mine_velvet", false);
	setvar("har_vmining_auto_detection", true);
	}

void set_farming_options()
	{
	announce(2, "set_farming_options");
	
	setvar("har_farm", true);
	setvar("har_farming_location", $location[The Castle in the Clouds in the Sky (Top Floor)]);
	setvar("har_farming_outfit", "");
	setvar("har_farming_sea_hat", $item[none]);
	setvar("har_farming_mood", "");
	monster olfact;
	if(have_skill($skill[Transcendent Olfaction]))
		olfact = $monster[Goth Giant];
	setvar("har_farming_olfacted_monster", olfact);
	setvar("har_farming_putty_olfacted", (have_foldable("putty") || have_foldable("doh")) && have_skill($skill[Transcendent Olfaction]));
	familiar fam;
	item fam_equip;
	if(have_familiar($familiar[Hobo Monkey]))
		{
		fam = $familiar[Hobo Monkey];
		fam_equip = $item[tiny bindle];
		}
	else if(have_familiar($familiar[Leprechaun]))
		{
		fam = $familiar[Leprechaun];
		fam_equip = $item[Meat detector];
		}
	setvar("har_farming_fam", fam);
	setvar("har_farming_famequip", fam_equip);
	setvar("har_farming_disco_combos", false);
	}

void set_rollover_options()
	{
	announce(2, "set_rollover_options");
	
	setvar("har_rollover_outfit", "");
	}

void create_data_files()
	{
	/* Initialises Harvest's data files */
	announce(2, "create_data_files");
	
	//Make sure we don't overwrite an exisiting data file. 
	//If the data file is empty then it doesn't matter if we overwrite it with a new one
	if(file_empty("HAR_Buffbot_Buffs.txt"))
		map_to_file(buffs_wanted, "HAR_Buffbot_Buffs.txt");
	if(file_empty("HAR_Effects_to_Remove.txt"))
		map_to_file(effects_to_remove, "HAR_Effects_to_Remove.txt");
	if(!get_property("har_profit_file_created").to_boolean())
		{
		map_to_file(statistics, "HAR_Daily_Profit_"+my_name()+".txt");
		set_property("har_profit_file_created", "true");
		}
	}

void set_default_settings()
	{
	/* Executes the functions that set Harvest up */
	announce(2, "set_default_settings");
	create_data_files();
	set_general_options();
	set_puttyfarming_options();
	set_bountyhunting_options();
	set_duckhunting_options();
	set_vmining_options();
	set_farming_options();
	set_rollover_options();
	}
	

/*******\
 Prepare 
\*******/
void save_prerun_settings()
	{
	/*	Saves a number of settings that Harvest might change into mafia properties so they can be 
		reset at the end of the day, or in case of a call to abort() */
	announce(2, "save_prerun_settings");
	set_property("har_prerun_mood", get_property("currentMood"));
	set_property("har_prerun_battleaction", get_property("battleAction"));
	set_property("har_prerun_ccs", get_property("customCombatScript"));
	set_property("har_prerun_bbs", get_property("betweenBattleScript"));
	set_property("har_prerun_counterscript", get_property("counterScript"));
	set_property("har_prerun_autoattack", get_auto_attack());
	}

void remove_unwanted_effects()
	{
	/* Removes any turns you may have of the effects specified in the relevant data file */
	announce(2, "remove_unwanted_effects");

	// If no effects were specified this should not have been called
	if(file_empty("har_effects_to_remove.txt"))
		failure("No unwanted effects specified");
	
	file_to_map("HAR_Effects_to_Remove.txt", effects_to_remove);
	
	foreach ef in effects_to_remove
		if(have_effect(ef.to_effect()) > 0)
			{
			announce(3, "Removing specified effect: "+ ef);
			cli_execute("shrug "+ef);
			}
	}

void set_mood()
	{
	/* Switches to the mood specified for your current activity */
	announce(2, "set_mood");

	string mood;
	switch (current_activity())
		{
		case "puttyfarm":
			mood = PUTTYFARMING_MOOD;
			break;
		case "bountyhunt":
			mood = BOUNTYHUNTING_MOOD;
			break;
		case "duckhunt":
			mood = DUCKHUNTING_MOOD;
			break;
		case "farm":
			mood = FARMING_MOOD;
			break;
		}

	if(mood == "")
		mood = "apathetic";
		
	cli_execute("mood "+mood);
	}

void set_ccs()
	{
	/* Sets your custom combat script to that which was specified in your vars file */
	announce(2, "set_ccs");
					
	if(CCS != "") // If the user has specified a CCS
		{
		set_property("battleAction", "custom combat script");
		
		if(get_property("customCombatScript") != CCS)
			set_property("customCombatScript", CCS);
	
		// Prevent autoattack settings from interfering
		set_auto_attack(0);
		}
	else
		announce(3, "No CCS specified");
	}
	
void set_bbs()
	{
	/* Sets your between battle script to that which was specified in your vars file, or does 
		nothing if no BBS was specified */
	announce(2, "set_bbs");
	
	if(BBS != "" && get_property("betweenBattleScript") != BBS)
		set_property("betweenBattleScript", BBS);
	}

int max_at_songs()
	{
	/* Returns the maximum number of AT songs you can currently hold in your head */
	announce(2, "max_at_songs");
	
	boolean four_songs = boolean_modifier("four songs");
	boolean extra_song = boolean_modifier("additional song");
	int max_songs = 3 + to_int(four_songs) + to_int(extra_song);
	
	announce(3, "You can currently hold "+ max_songs +" AT songs in your head");
	return max_songs;
	}
	
int active_at_songs()
	{
	/* Returns the number of AT songs you currently have active */
	announce(2, "num_at_songs");
	
	int num_at_songs = 0;
	for skill_num from 6001 to 6040
		{
		skill the_skill = skill_num.to_skill();
		effect the_effect = the_skill.to_effect();
		int num_turns = have_effect(the_effect);
		
		if(the_skill != $skill[none] && skill_num != 6025 && num_turns > 0)
			num_at_songs += 1;
		}
	
	announce(3, "You have "+ num_at_songs +" AT songs active");
	return num_at_songs;
	}
	
boolean head_full()
	{
	/* Returns true if you have no slots free for AT songs */
	announce(2, "head_full");
	return active_at_songs() == max_at_songs();
	}

boolean is_at_buff(effect buff)
	{
	/* Returns true if the specified effect is an Accordion Thief buff */
	announce(2, "is_at_buff");
	for skill_num from 6001 to 6040
		{
		skill the_skill = skill_num.to_skill();
		if(the_skill != $skill[none] && skill_num != 6025 && buff == the_skill.to_effect())
			return true;
		}
	
	return false;
	}
	
effect cheapest_at_buff()
	{
	/*	Returns the least valuable AT buff you have active based on number of turns, MP cost and your
		ability to cast the skill (it's more important to preserve turns of effects you can only get
		from a buffbot) */
	announce(2, "cheapest_at_buff");
	
	effect cheapest;
	int temp_cost = 999999;
	
	for skill_num from 6001 to 6040
		{
		skill the_skill = skill_num.to_skill();
		effect the_effect = the_skill.to_effect();
		int num_turns = have_effect(the_effect);
		
		if(the_skill != $skill[none] && skill_num != 6025 && num_turns > 0)
			{
			// Inserting Theraze's fix (#324), keeping old code for now, just in case
			###int cost = num_turns/turns_per_cast(the_skill) * mp_cost(the_skill);
			int cost = num_turns/(turns_per_cast(the_skill) > 0 ? turns_per_cast(the_skill) : 1) * mp_cost(the_skill);
			
			if(have_skill(the_skill))
				cost -= 50000; // If you can cast it yourself it's less important to preserve remaining turns
			if(buffs_wanted contains the_effect)
				cost += 100000; // Don't shrug a buff you want to get
			if($effects[chorale of companionship, The Ballad of Richie Thingfinder] contains the_effect)
				cost += 5000; // Hobo buffs are harder to acquire
			
			if(cost < temp_cost)
				{
				cheapest = the_effect;
				temp_cost = cost;
				}
			}
		}

	return cheapest;
	}
	
boolean buffbot_online(string buffbot)
	{
	/* Returns true if the specified buffbot is online */
	announce(2, "buffbot_online");
		
	string [string] offline_buffbots;

	if(offline_buffbots contains buffbot) // If the bot was previously offline
		return false;
	else if(is_online(buffbot)) // Make sure bot is still online
		{
		announce(3, buffbot +" is online");
		return true;
		}
	else // Bot wasn't previously seen as being offline but is now
		{
		offline_buffbots [buffbot] = "";
		announce(3, buffbot +" is offline");
		return false;
		}
	}
	
boolean has_buff(string buffbot, effect buff)
	{
	/* Returns true if the specified buffbot can give the specified buff */
	announce(2, "has_buff");
	return buffbot_data [buffbot, buff].to_boolean();
	}
	
void request_buff(effect the_effect, int turns_needed)
	{
	/*	Attempts to get <my_adventures()> turns of the specified buff from a buffbot
		Will not shrug AT buffs if you have too many to receive the effect */
	announce(2, "request_buff");
	
	int max_time = 60; // The max time to wait for a buffbot to respond
	int pause = 5; // How long to wait before checking if a buffbot has responded
	int turns_still_needed;
	
	refresh_status();
	
	if(have_effect(the_effect) < my_adventures() || the_effect == $effect[Ode to Booze])
		{
		skill the_skill = the_effect.to_skill();
		
		// Inserting Theraze's fix (#326), keeping old code for now, just in case
		###int casts_needed = ceil(turns_needed / turns_per_cast(the_skill).to_float());
		int casts_needed = ceil(turns_needed / (turns_per_cast(the_skill) > 0 ? turns_per_cast(the_skill) : 1).to_float());
	
		if(have_skill(the_skill)) // Don't be lazy - Cast the buff yourself if you have the skill
			{
			announce(1, "You can cast "+ the_effect +" yourself so you probably shouldn't mooch off a bot");
			use_skill(casts_needed, the_skill);
			}
		else
			{
			// Find a buffbot from which to acquire the buff
			foreach buffbot in buffbot_data
				{
				turns_still_needed = turns_needed - have_effect(the_effect);
				
				if(turns_still_needed > 0 && has_buff(buffbot, the_effect) && buffbot_online(buffbot))
					{
					announce(1, "Attempting to get "+ turns_still_needed +" turns of "+ the_effect +" from "+ buffbot);
					
					int meat = max(0, buffbot_data [buffbot, the_effect]);
					string message = "";
					if(buffbot == "buffy")
						message = turns_still_needed +" "+ the_effect.to_string();
					
					int initial_turns = have_effect(the_effect);
					kmail(buffbot, message, meat);
					int time_waited = 0;
					boolean buffbot_responded = false;
					
					while(!buffbot_responded && time_waited < max_time)
						{
						waitq(pause);
						time_waited += pause;
						refresh_status();
						buffbot_responded = have_effect(the_effect) > initial_turns;
						
						switch (time_waited)
							{
							case 10:
								announce(1, ". . .");
								break;
							case 20:
								announce(1, "Hmm, that buffbot sure is taking its time");
								break;
							case 30:
								announce(1, ". . .");
								break;
							case 40:
								announce(1, "Still waiting...");
								break;
							case 50:
								announce(1, ". . .");
								break;
							case 60:
								announce(1, "OK, I give up, let's try another bot");
							}						
						}
						
					if(buffbot_responded)
						{
						if(have_effect(the_effect) < turns_needed)
							announce(1, buffbot +" responded but you still need more turns");
						else
							announce(1, "Buffbot request successful");
						}
					}				
				}
			
			if(turns_still_needed > 0)
				{				
				item recording = to_item("recording of "+ the_effect.to_string());
				
				if(recording != $item[none] && BUY_RECORDINGS)
					{
					announce(1, "Couldn't get "+ the_effect +" from a bot, switching to recordings");
					int recordings_needed = ceil(turns_still_needed/20.0);
					buy(recordings_needed - item_amount(recording), recording);
					use(recordings_needed, recording);
					}
				else
					announce(-1, "Could not get required number of turns of "+ the_effect +", skipping");
				}
			}
		}
	else
		announce(3, "Didn't try to get "+ the_effect +", already had "+ have_effect(the_effect) +" turns");
	}
	
void request_buff(effect the_effect)
	{
	/* Overloader for 2 parameter version */
	request_buff(the_effect, my_adventures() - have_effect(the_effect));
	}
	
int num_at_buffs_wanted()
	{
	/* Returns the number of AT buffs the user has requested Harvest to get form a buffbot */
	announce(2, "num_at_buffs_wanted");
	int total;
	foreach buff in buffs_wanted
		if(is_at_buff(buff))
			total += 1;
	return total;
	}	
	
void get_buffbot_buffs()
	{
	/*	Attempts to get the effects specified in the relevant data file from a number of buffbots, 
		shrugging AT buffs to make room if necessary (only shrugs buffs not specified in the file) */
	announce(2, "get_buffbot_buffs");
	announce(1, "Getting buffbot buffs");
	
	if(num_at_buffs_wanted() > max_at_songs())
		failure("You specified more AT buffs in HAR_Buffbot_Buffs.txt than you can currently hold in your head");
	
	int free_slots = max_at_songs() - active_at_songs();
	int slots_needed;

	foreach buff in buffs_wanted
		if(is_at_buff(buff) && have_effect(buff) == 0)
			slots_needed += 1;
	
	int num_to_shrug = max(0, slots_needed - free_slots);
	
	while(num_to_shrug > 0)
		{
		cli_execute("shrug "+ cheapest_at_buff().to_string());
		num_to_shrug -= 1;
		}
	
	foreach buff in buffs_wanted
		{
		announce(3, "Now considering: "+ buff);
		request_buff(buff);
		}
	}
	
void equip_gear(string activity)
	{
	/*	Equips the outfit, familiar and familar equipment chosen by the user for the specified 
		<activity> */
	announce(2, "equip_gear");
	string outfit;
	familiar fam;
	item fam_equip;

	if(have_foldable("cheese"))
		get_foldable($item[stinky cheese eye]);
	if(have_skill($skill[Torso Awaregness]) && have_foldable("origami"))
		get_foldable($item[origami pasties]);

	switch (current_activity())
		{
		case "puttyfarm":
			outfit = PUTTYFARMING_OUTFIT;
			fam = PUTTYFARMING_FAM;
			fam_equip = PUTTYFARMING_FAMEQUIP;
			break;
		case "bountyhunt":
			outfit = BOUNTYHUNTING_OUTFIT;
			fam = BOUNTYHUNTING_FAM;
			fam_equip = BOUNTYHUNTING_FAMEQUIP;
			break;
		case "duckhunt":
			outfit = DUCKHUNTING_OUTFIT;
			fam = DUCKHUNTING_FAM;
			fam_equip = DUCKHUNTING_FAMEQUIP;
			break;
		case "vmine":
			outfit = VMINING_OUTFIT;
			fam = $familiar[none];
			fam_equip = $item[none];
		case "farm":
			outfit = FARMING_OUTFIT;
			fam = FARMING_FAM;
			fam_equip = FARMING_FAMEQUIP;
			break;
		default:
			failure("No activity was specified");
		}

	outfit(outfit);
	
	if(my_familiar() != fam && fam != $familiar[none])
		use_familiar(fam);
	
	if(!have_equipped(fam_equip) && fam_equip != $item[none])
		equip($slot[familiar], fam_equip);
	
	// We need to equip the sugar shield after our normal fam_equip so that mafia knows what to switch to if the former breaks
	if(USE_SHIELDS && available_amount($item[sugar shield]) > 0 && (activity == "farm" || activity == "puttyfarm"))
		equip($item[sugar shield]);	
	}

void equip_gear()
	{
	/*	Overloader for the parameterised version. Equips gear based on the mafia property set by 
		other functions (this version does not force an activity) */
	announce(2, "equip_gear");
	equip_gear(current_activity());
	}
	
boolean equip_song_raisers()
	{
	/* Equips items to raise the number of songs you can hold in your head */
	announce(2, "equip_song_raisers");
	
	boolean result = false;
	
	if(!boolean_modifier("Four Songs")) 
		result = maximize("Four Songs -tie", false); 
	if(!boolean_modifier("Additional Song")) 
		result = result || maximize("Additional Song -tie", false);
		
	return result;
	}
	
void fill_organs()
	{
	/*	Uses the specified consumption script to fill your organs
		If the relevant option is set to true eats a fortune cookie if you have no active fortune 
		cookie counter, and intelligently determines how much room to leave for cookies later in the
		day (this information is passed on to EatDrink.ash, but not to any other consumption scripts */
	announce(1, "Filling organs");
	announce(2, "fill_organs");
	if(CONSUME_SCRIPT == "")
		failure("No consumption script was specified");
	
	if(my_fullness() < fullness_limit() || my_inebriety() < inebriety_limit() || my_spleen_use() < spleen_limit())
		{
		// Eat a cookie if no current counters and if doing SRs
		if(DOSEMIRARES && my_fullness() < fullness_limit())
			{
			/* If we have an active couter, the amount of fullness we need to leave for cookies
			(cookie_room) will be one less than the number of SRs we expect to get today because 
			we'll get one of those SRs without having to eat a cookie. If we don't have an active 
			counter then we'll be eating a cookie immediately anyway, so cookie_room will be reduced
			by one too. Therefore cookie_room is always one less than num_srs() */
			
			cookie_room = max(0, num_srs()-1);
	
			// If you don't have an active SR counter eat a cookie
			if(!sr_counter_active())
				{
				if(get_property("valueOfAdventure").to_int() > mall_price($item[milk of magnesium]) && have_effect($effect[Got Milk]) == 0)
					{
					retrieve_item(1, $item[milk of magnesium]);
					use(1, $item[milk of magnesium]);
					}
					
				if(get_property("valueOfAdventure").to_int() * 3 > mall_price($item[munchies pill]))
					{
					retrieve_item(1, $item[munchies pill]);
					use(1, $item[munchies pill]);
					}
				
				retrieve_item(1, $item[fortune cookie]);
				eatsilent(1, $item[fortune cookie]);
				}
			}
		
		// Get ode if necessary
		if(have_effect($effect[Ode to Booze]) < (inebriety_limit() - my_inebriety()))
			{
			// Make room
			if(head_full())
				if(!equip_song_raisers())
					cli_execute("shrug "+ cheapest_at_buff().to_string());
			
			if(!have_skill($skill[The Ode to Booze]))
				request_buff($effect[Ode to Booze], inebriety_limit());
			}
		
		announce(3, "Cookie_room is currently "+ cookie_room);
		
		if(CONSUME_SCRIPT.to_lower_case() == "eatdrink.ash")
			eatdrink(fullness_limit()-cookie_room, inebriety_limit(), spleen_limit(), false);
		else
			cli_execute("run "+ CONSUME_SCRIPT);
		
		if(my_fullness() < fullness_limit()-cookie_room || my_inebriety() < inebriety_limit() || my_spleen_use() < spleen_limit())
			failure(CONSUME_SCRIPT +" failed to fill your organs completely");	
			
		if(have_effect($effect[Ode to Booze]) > 0)	
			cli_execute("shrug ode to booze");
		}
	else
		announce(3, "Your organs are already full");
	}

void get_buffing_aids()
	{
	/* Makes sure you have items to increase the number of turns per cast of AT and TT buffs */
	announce(2, "get_buffing_aids");
	if( item_amount($item[Mace of the Tortoise]) == 0 && !have_equipped($item[Mace of the Tortoise]) && 
		item_amount($item[Chelonian Morningstar]) == 0 && !have_equipped($item[Chelonian Morningstar]))
		retrieve_item(1, $item[Mace of the Tortoise]);
	if( item_amount($item[Rock and Roll Legend]) == 0 && !have_equipped($item[Rock and Roll Legend]) && 
		item_amount($item[Squeezebox of the Ages]) == 0 && !have_equipped($item[Squeezebox of the Ages]))
		retrieve_item(1, $item[Rock and Roll Legend]);
	}

void summon_demon()
	{
	/* Summons the demon specified in your vars file */
	announce(2, "summon_demon");
	switch (DEMON)
		{
		case "pies":
			demon = get_property("demonName1");
			break;
		case "drinks":
			demon = get_property("demonName7");
			break;
		case "preternatural greed":
			demon = get_property("demonName2");
			break;
		case "fit to be tide":
			demon = get_property("demonName3");
			break;
		case "big flaming whip":
			demon = get_property("demonName4");
			break;
		case "demonic taint":
			demon = get_property("demonName5");
			break;
		case "burning, man":
			demon = get_property("demonName9");
			break;
#		case "the pleasures of the flesh":
#			demon = get_property("   ");
#			break;
		case "existential torment":
			demon = get_property("demonName8");
			break;		
		default:
			demon = "";
		}
	
	if(!get_property("demonSummoned").to_boolean())
		{
		if(demon != "")
			cli_execute("summon "+demon);
		}
	else
		announce(3, "You've already summoned a demon today");
	}
	
void visit_friars()
	{
	/* Gets the friar blessing specified in your vars file */
	announce(2, "visit_friars");
	if(!get_property("friarsBlessingReceived").to_boolean())	
		cli_execute("friars "+FRIAR_BLESSING);
	else
		announce(3, "Already visited the friars today");
	}

void attend_concert()
	{
	/* Gets the concert effect specified in your vars file */
	announce(2, "attend_concert");
	if(!get_property("concertVisited").to_boolean())
		cli_execute("concert "+CONCERT_EFFECT);
	else
		announce(3, "Already gone to a concert today");
	}
	
void play_pool()
	{
	/* Plays pool using the style specified in your vars file */
	announce(2, "play_pool");
	if(get_property("_poolGames").to_int() < 3)
		cli_execute("pool "+POOL_STYLE+", "+POOL_STYLE+", "+POOL_STYLE);
	else
		announce(3, "You've played enough pool for today");
	}

void visit_hatter()
	{
	/* Gets the hatter buff specified in your vars file */
	announce(2, "visit_hatter");
	
	if(!get_property("_har_visited_hatter").to_boolean())
		{
		int chars_needed;
		if(HATTER_BUFF == $effect[Dances with Tweedles])
			chars_needed = 22;
		else if(HATTER_BUFF == $effect[Quadrilled])
			chars_needed = 28;
		else
			failure("Specified hatter buff could not be matched to a character number");
	
		item the_hat = hatter_hat(chars_needed);
		
		if(the_hat == $item[none] || !can_equip(the_hat))
			announce(-1, "You do not have the appropriate hat to get the specified hatter buff");
		else
			{
			equip(the_hat);
			
			if(have_effect($effect[Down the Rabbit Hole]) == 0)
				{
				if(item_amount($item[&quot;DRINK ME&quot; potion]) == 0)
					buy(1, $item[&quot;DRINK ME&quot; potion]);
				
				use(1, $item[&quot;DRINK ME&quot; potion]);
				}
			
			visit_url("place.php?whichplace=rabbithole&action=rabbithole_teaparty");
			visit_url("choice.php?pwd&whichchoice=441&option=1");
			
			set_property("_har_visited_hatter", true);
			}
		}
	else
		announce(3, "You've already visited the hatter today");
	}

void get_farming_effects()
	{
	/* 	Executes the various functions that get the farming-related effects specified in your vars
		file */
	announce(2, "get_farming_effects");
	if(!file_empty("har_effects_to_remove.txt")) // If HAR_Effects_to_Remove has anything in it
		{
		announce(1, "Removing unwanted effects");
		remove_unwanted_effects();
		}
	if(!file_empty("har_buffbot_buffs.txt"))
		get_buffbot_buffs();
	if(DEMON != "none")
		summon_demon();
	if(FRIAR_BLESSING != "none")
		visit_friars();
	if(CONCERT_EFFECT != $effect[none])
		attend_concert();
	if(POOL_STYLE != "none")
		play_pool();
	if(HATTER_BUFF != $effect[none])
		visit_hatter();
	if(item_amount($item[The Legendary Beat]) > 0 && !get_property("_legendaryBeat").to_boolean())
		use(1, $item[The Legendary Beat]);
	}

void preconsumption_script()
	{
	/* Runs the preconsumption script specified in your vars file */
	announce(2, "preconsumption_script");
	if(PRECONSUMPTION_SCRIPT != "")
		cli_execute(PRECONSUMPTION_SCRIPT);
	set_ccs(); // In case it was changed
	set_bbs();
	}

void postconsumption_script()
	{
	/* Runs the postconsumption script specified in your vars file */
	announce(2, "postconsumption_script");	
	if(POSTCONSUMPTION_SCRIPT != "")
		cli_execute(POSTCONSUMPTION_SCRIPT);
	set_ccs(); // In case it was changed
	set_bbs();
	}

void initialise()
	{
	/* Runs the various functions that get Harvest ready to farm each day */
	announce(2, "initialise");
	announce(1, "Initialising");
	set_property("har_current_activity", "prefarm");

	update_profit_datafile(); // For users updating to v2.0
	closet_meat();
	
	if(get_property("_har_startadventures") == "")	
		set_property("_har_startadventures", my_turncount());
	
	if(get_property("_har_startmeat") == "")
		set_property("_har_startmeat", my_meat()+my_closet_meat());
	
	save_prerun_settings();
	set_ccs();
	set_bbs();
	}


void prep_for_adventure()
	{
	/* Carries out any actions that need to be performed immediately before spending an adventure */
	announce(2, "prep_for_adventure");
	if(my_adventures() == 0) {
		/* Pantsgiving can raise fullness limit while adventuring, so handle that case */
		if (my_fullness() < fullness_limit())
			fill_organs();
		else
			failure("Oops. You've run out of adventures. That shouldn't have happened");
	}
	if(!file_empty("har_effects_to_remove.txt"))	
		remove_unwanted_effects();
	}


// Bountyhunting functions
void get_monster_copier()
	{
	/*	Retrieves your putty/doh and folds it into sheet/box form (does nothing if you 
	have a putty/doh monster) */
	announce(2, "get_monster_copier");
	
	if (PUTTYFARM)
		failure("Conflicting settings: You can't farm your putty AND bountyhunt using spooky putty");
	
	if (have_copied_monster())
		announce(3, "You have a putty or doh monster in your inventory, but we'll deal with that in a minute");
	else
		{
		if (have_foldable("putty"))
			get_foldable($item[Spooky Putty sheet]);
		else if (have_foldable("doh"))
			get_foldable($item[Rain-Doh black box]);
		else
			failure("You don't appear to have any putty or doh");
		}
	}

boolean finished_easy_bountyhunting(string bhh) {
	if(!BOUNTYHUNT_EASY) {
		return true;
	}

	if (contains_text(bhh, "took on an Easy Bounty today")) {
		return true;
	}
	
	bounty easy_bounty_item;
	if (get_property("currentEasyBountyItem") != "") {
		easy_bounty_item = get_property("currentEasyBountyItem").to_bounty();
	} else if (get_property("_untakenEasyBountyItem") != "") {
		easy_bounty_item = get_property("_untakenEasyBountyItem").to_bounty();
	} else {
		return true;
	}

	return !can_adv(easy_bounty_item.location, false);
}

boolean finished_hard_bountyhunting(string bhh) {
	if(!BOUNTYHUNT_HARD) {
		return true;
	}

	if (contains_text(bhh, "took on an Hard Bounty today")) {
		return true;
	}
	
	bounty hard_bounty_item;
	if (get_property("currentHardBountyItem") != "") {
		hard_bounty_item = get_property("currentHardBountyItem").to_bounty();
	} else if (get_property("_untakenHardBountyItem") != "") {
		hard_bounty_item = get_property("_untakenHardBountyItem").to_bounty();
	} else {
		return true;
	}

	return !can_adv(hard_bounty_item.location, false);
}

boolean finished_special_bountyhunting(string bhh) {
	if(!BOUNTYHUNT_SPECIAL) {
		return true;
	}

	if (contains_text(bhh, "took on an Special Bounty today")) {
		return true;
	}
	
	bounty special_bounty_item;
	if (get_property("currentSpecialBountyItem") != "") {
		special_bounty_item = get_property("currentSpecialBountyItem").to_bounty();
	} else if (get_property("_untakenSpecialBountyItem") != "") {
		special_bounty_item = get_property("_untakenSpecialBountyItem").to_bounty();
	} else {
		return true;
	}

	return !can_adv(special_bounty_item.location, false);
}

boolean finished_bountyhunting() {
	if (my_inebriety() > inebriety_limit()) {
		return true;
	}

	string bhh = visit_url("bounty.php");

	return finished_easy_bountyhunting(bhh) && finished_hard_bountyhunting(bhh) && finished_special_bountyhunting(bhh);
}
	
/*********\
 Adventure 
\*********/
void beat_up_dolphins()
	{
	/* Gets the last stolen item back if it's worth the cost of a dolphin whistle */
	announce(2, "beat_up_dolphins");
	
	item stolen_item = get_property("dolphinItem").to_item();
	
	if(get_counters("Dolphin",1,11) == "" && stolen_item != $item[none])
		{
		announce(3, "Counter expired and stolen item is "+ stolen_item);
		
		int price_stolen = mall_price(stolen_item);
		int price_sand_dollar = mall_price($item[sand dollar]);
		int price_whistle = mall_price($item[dolphin whistle]);
		
		// Get the item back, if it's worth it
		if(min(price_sand_dollar, price_whistle) < price_stolen)
			{
			announce(1, "HEY! That dolphin stole something! Proceeding to lay down the smack");
			
			// Get a whistle
			if(item_amount($item[dolphin whistle]) == 0)
				{
				announce(3, "Acquiring a dolphin whistle");
				
				if(price_sand_dollar < price_whistle)
					{
					announce(3, "Buying whistle from big brother");
					retrieve_item(1, $item[sand dollar]);
					if(visit_url("monkeycastle.php?pwd&action=buyitem&whichitem=3997&quantity=1").to_string() == "")
						announce(3, "You don't have access to big brother, continuing to mall");
					}
				
				if(item_amount($item[dolphin whistle]) == 0)
					{
					announce(3, "Buying a whistle from the mall");
					buy(1, $item[dolphin whistle]);
					}
				}
			
			use(1, $item[dolphin whistle]);
			}
		}
	else
		announce(3, "Counter not up yet, or no item has been stolen");
	}

void copyfarm()
	{
	announce(2, "copyfarm");
	announce(1, "Commencing copyfarming", true);

	if(!have_copied_monster())
		failure("You have no putty/doh monster");
		
	set_property("har_current_activity", "puttyfarm");
	equip_gear();
	set_mood();
	cli_execute("conditions clear");
	
	while(copies_available() > 0)
		{
		announce(2, get_property("spookyPuttyCopiesMade"));
		announce(2, get_property("_raindohCopiesMade"));

		prep_for_adventure();
		if (!use(1, $item[Spooky Putty monster]))
			use(1, $item[Rain-Doh box full of monster]);
		}
	
	announce(1, "Copyfarming complete");
	}

void duck_hunt()
	{
	announce(2, "duck_hunt");
	announce(1, "Commencing duck hunting", true);
	
	set_property("har_current_activity", "duckhunt");
	
	int num_ducks = num_ducks();
		
	equip_gear();
	set_mood();
	cli_execute("mood execute");
	cli_execute("conditions clear");
	
	int ducks_angered;
	boolean out_of_ducks;
	while(ducks_angered < num_ducks && !out_of_ducks)
		{
		if(!adventure(1, $location[McMillicancuddy's Farm]))
			{
			out_of_ducks = true;
			ducks_angered += 1;
			}
		}

	announce(1, "Duck hunting complete");
	}

void volcano_mine()
	{
	announce(2, "volcano_mine");
	announce(1, "Commencing volcano mining", true);

	set_property("har_current_activity", "vmine");

	int adv_limit = VMINING_ADVENTURE_LIMIT;

	if (VMINING_ADVENTURE_LIMIT == 0)
		adv_limit = my_adventures();

	mine_volcano(adv_limit, VMINING_MINE_VELVET, VMINING_AUTO_DETECTION, VMINING_OUTFIT);

	announce(1, "Volcano mining complete");
	}

void bountyhunt(bounty bounty_item) {
	if(!can_adv(bounty_item.location, false)) {
		return;
	}
	
	announce(1, "Commencing bounty hunting for " + bounty_item.plural + " in " + bounty_item.location + ".", true);
	
	set_property("har_current_activity", "bountyhunt");
	set_property("_har_bounty_expected_lucre", item_amount($item[filthy lucre]) + 1);
	
	// Clear On the Trail
	if(have_effect($effect[On the Trail]) > 0 && get_property("olfactedMonster").to_monster() != bounty_item.monster) {
		cli_execute("shrug On the Trail");
	}

	if(!FARM || bounty_item.location != FARMING_LOCATION) {
		if(BOUNTYHUNT_WITH_PUTTY) {
			get_monster_copier();
		}
		
		equip_gear();
		set_mood();
		cli_execute("mood execute");
			
		int adventures_spent = 0;
		cli_execute("conditions clear");
		while(item_amount($item[filthy lucre]) < get_property("_har_bounty_expected_lucre").to_int() && adventures_spent < 70) {
			prep_for_adventure();
			
			if(BOUNTYHUNT_WITH_PUTTY) {
				while(have_copied_monster()) {
					//If it doesn't drop our bounty item Harvest Combat will deal with it and free up putty/doh
					if(use(1, $item[Spooky Putty monster]) || use(1, $item[Rain-Doh box full of monster]))
						adventures_spent += 1;
					else {
						announce(-1, "Unable to use your putty/doh monster, probably means mafia is having issues, refreshing.");
						cli_execute("refresh");
					}
				}
			}

			// Check again in case we finished the bounty with putty/doh
			if(item_amount($item[filthy lucre]) < get_property("_har_bounty_expected_lucre").to_int()) {
				can_adv(bounty_item.location, true);
				adventure(1, bounty_item.location);
				adventures_spent += 1;
			}
		}
		
		if(item_amount($item[filthy lucre]) < get_property("_har_bounty_expected_lucre").to_int()) {
			failure("Something went wrong: You spent " + adventures_spent + " adventures and didn't finish your bounty.");
		}
	
		announce(1, "Bounty hunting for " + bounty_item.plural + " in " + bounty_item.location + " complete.");
	}
	else {
		announce(1, bounty_item.location + " is your farming location, proceeding to farm as normal.");
	}
	
	// Abort if you can buy olfaction for the first time
	if(!have_skill($skill[Transcendent Olfaction]) && available_amount($item[filthy lucre]) == 200) {
		print("You made it to 200 lucre. Time to buy your manual!", "green");
		failure("");
	}
}

void bountyhunteasy() {
	announce(2, "bountyhunteasy");

	if (my_inebriety() > inebriety_limit()) {
		return;
	}
	
	if (!BOUNTYHUNT_EASY) {
		return;
	}
	
	bounty easy_bounty_item;
	if (get_property("currentEasyBountyItem") != "") {
		easy_bounty_item = get_property("currentEasyBountyItem").to_bounty();
	} else if (get_property("_untakenEasyBountyItem") != "") {
		easy_bounty_item = get_property("_untakenEasyBountyItem").to_bounty();
		if(can_adv(easy_bounty_item.location, true)) {
			visit_url("bounty.php?action=take" + easy_bounty_item.kol_internal_type);
			announce(3, "Accepted easy bounty for " + easy_bounty_item.plural + " in " + easy_bounty_item.location + ".");
		}
	} else {
		return;
	}
	
	bountyhunt(easy_bounty_item);
}

void bountyhunthard() {
	announce(2, "bountyhunthard");

	if (my_inebriety() > inebriety_limit()) {
		return;
	}
	
	if (!BOUNTYHUNT_HARD) {
		return;
	}
	
	bounty hard_bounty_item;
	if (get_property("currentHardBountyItem") != "") {
		hard_bounty_item = get_property("currentHardBountyItem").to_bounty();
	} else if (get_property("_untakenHardBountyItem") != "") {
		hard_bounty_item = get_property("_untakenHardBountyItem").to_bounty();
		if(can_adv(hard_bounty_item.location, true)) {
			visit_url("bounty.php?action=take" + hard_bounty_item.kol_internal_type);
			announce(3, "Accepted hard bounty for " + hard_bounty_item.plural + " in " + hard_bounty_item.location + ".");
		}
	} else {
		return;
	}
	
	bountyhunt(hard_bounty_item);
}

void bountyhuntspecial() {
	announce(2, "bountyhuntspecial");

	if (my_inebriety() > inebriety_limit()) {
		return;
	}
	
	if (!BOUNTYHUNT_SPECIAL) {
		return;
	}
	
	bounty special_bounty_item;
	if (get_property("currentSpecialBountyItem") != "") {
		special_bounty_item = get_property("currentSpecialBountyItem").to_bounty();
	} else if (get_property("_untakenSpecialBountyItem") != "") {
		special_bounty_item = get_property("_untakenSpecialBountyItem").to_bounty();
		if(can_adv(special_bounty_item.location, true)) {
			visit_url("bounty.php?action=take" + special_bounty_item.kol_internal_type);
			announce(3, "Accepted special bounty for " + special_bounty_item.plural + " in " + special_bounty_item.location + ".");
		}
	} else {
		return;
	}
	
	bountyhunt(special_bounty_item);
}

void farm()
	{
	announce(2, "farm");
	announce(1, "Commencing farming", true);

	set_property("har_current_activity", "farm");
	
	get_buffing_aids();
	get_farming_effects();
	
	if(PUTTY_OLFACTED)
		get_monster_copier();
	
	equip_gear();
	set_mood();
	cli_execute("conditions clear");
	while(!finished_farming())
		{
		prep_for_adventure();
		
		if(is_underwater(FARMING_LOCATION))
			{
			if(have_effect($effect[Fishy]) == 0)
				{
				announce(-1, "You've run out of Fishy!");
				if(my_adventures() == 1)
					failure("You don't have enough adventures to adventure in the sea. Get some more turns of fishy");
				}
			
			// Take advantage of really deep breath and swap hats
			if(SEA_HAT != $item[none])
				{
				if(!have_equipped(SEA_HAT))
					{
					if(have_effect($effect[Really Deep Breath]) > 0)
						equip(SEA_HAT);
					}
				else if(have_effect($effect[Really Deep Breath]) == 0)
					cli_execute("outfit "+ FARMING_OUTFIT);
				}
				
			beat_up_dolphins();
			}
		
		// Olfaction stuff
		if(MONSTER_TO_SNIFF != $monster[none])
			{
			// If we're on the wrong trail, shrug
			if(have_effect($effect[On the Trail]) > 0 && get_property("olfactedMonster").to_monster() != MONSTER_TO_SNIFF)
				cli_execute("shrug on the trail");
			
			// If have monster to olfact in putty/doh and not on the trail, use putty/doh
			if(PUTTY_OLFACTED && have_effect($effect[On the Trail]) == 0)
				{
				if(get_property("spookyPuttyMonster").to_monster() == MONSTER_TO_SNIFF  || (get_property("rainDohMonster").to_monster() == MONSTER_TO_SNIFF))
					{
					if(!use(1, $item[Spooky Putty monster]) && !use(1, $item[Rain-Doh box full of monster]))
						{
						announce(-1, "Unable to use your putty/doh monster, probably means mafia is having issues, refreshing");
						cli_execute("refresh");
						}
					}
				else if(get_property("spookyPuttyMonster") != "" && (get_property("rainDohMonster") != ""))
					failure("You have a monster that is not a "+ MONSTER_TO_SNIFF.to_string() +" in your putty/doh. That shouldn't have happened");
				}
			}
				
		adventure(1, FARMING_LOCATION);
		}
	
	announce(1, "Farming complete");
	}


/*****************\
 Finish up for Day 
\*****************/
void cast_rainbow_gravitation()
	{
	/* Casts rainbow gravitation as many times as possible, buying wads as needed */
	announce(2, "cast_rainbow_gravitation");
	int summons_left = 3 - get_property("prismaticSummons").to_int();
	foreach wad in $items[hot wad, cold wad, spooky wad, stench wad, sleaze wad, twinkly wad]
		retrieve_item(summons_left, wad);
	
	if(summons_left > 0)
		{
		announce(1, "Casting Rainbow Gravitation");
		use_skill(summons_left, $skill[Rainbow Gravitation]);
		}
	}
	
void improve_spirits() {
	/* Optimally uses up any remaining Still summons for the day, buying items as necessary */
	announce(2, "improve_spirits");
	// Many thanks to Bale for providing this code! http://kolmafia.us/showthread.php?1818-OCD-Inventory-control&p=60006&viewfull=1#post60006
	
	if(stills_available() < 1)
		return;
	
	announce(1, "Using the Still");
	
	item [item] upgrade;
	upgrade[$item[bottle of gin]] = $item[bottle of Calcutta Emerald];
	upgrade[$item[bottle of rum]] = $item[bottle of Lieutenant Freeman];
	upgrade[$item[bottle of tequila]] = $item[bottle of Jorge Sinsonte];
	upgrade[$item[bottle of vodka]] = $item[bottle of Definit];
	upgrade[$item[bottle of whiskey]] = $item[bottle of Domesticated Turkey];
	upgrade[$item[boxed wine]] = $item[boxed champagne];
	upgrade[$item[grapefruit]] = $item[tangerine];
	upgrade[$item[lemon]] = $item[kiwi];
	upgrade[$item[olive]] = $item[cocktail onion];
	upgrade[$item[orange]] = $item[kumquat];
	upgrade[$item[soda water]] = $item[tonic water];
	upgrade[$item[strawberry]] = $item[raspberry];
	upgrade[$item[bottle of sewage schnapps]] = $item[bottle of Ooze-O];
	upgrade[$item[bottle of sake]] = $item[bottle of Pete's Sake];

	item best;
	int profit = 0;
	int test_profit;
	foreach key in upgrade {
		if(historical_age(upgrade[key])>1)
			mall_price(upgrade[key]);
		if(historical_age(key)>1)
			mall_price(key);
		test_profit = historical_price(upgrade[key]) - historical_price(key);
		if(test_profit > profit)
			{
			best = key;
			profit = test_profit;
			}
		}

	announce(1, "Creating " + stills_available()+ " " +upgrade[best]+ " to sell @ "+historical_price(upgrade[best]));
	retrieve_item(stills_available(), best);
	create(stills_available(), upgrade[best]);
	}

int run_ocd() {
	/*	Runs OCD Inventory Control.ash and returns the amount of meat made from kbay auctions and
		mall sales */
	announce(2, "run_ocd");
	announce(1, "Tidying your inventory");
	
	record { 
		string action; 
		int q; 
		string info; 
		string message; 
	} [item] default_ocd_data;
	
	int ocd_profit;
	if(DEFAULT_OCDDATA && FARMING_LOCATION == $location[The Castle in the Clouds in the Sky (Top Floor)]) {
		announce(3, "Using default OCD data");
		
		// Load Data file
		file_to_map("OCDdata_HAR_Default.txt", default_ocd_data);
		
		ocd_profit = ocd_control(false, "OCDdata_HAR_Default");
		}
	else
		ocd_profit = ocd_control(false);
		
	if(ocd_profit == -1)
		announce(-1, "Looks like OCD wasn't able to sell anything. Make sure you've set up OCD properly");

	return ocd_profit;
	}
	
void overdrink() {
	/*	Drinks a nightcap using your consumption script. Will make space for ode by shurgging an AT
		buff if necessary, and will attempt to get a shot of ode from a buffbot if you cannot cast it
		yourself (but will NOT cast ode if you can cast it yourself - that's up to the consumption
		script) */
	announce(2, "overdrink");
	
	announce(1, "Overdrinking");
	
	if(CONSUME_SCRIPT == "")
		failure("No consumption script was specified");
	
	// Get ode if necessary
	if(have_effect($effect[Ode to Booze]) < (inebriety_limit() + 10 - my_inebriety())) {
		// Make room
		if(head_full())
			if(!equip_song_raisers())
				cli_execute("shrug "+ cheapest_at_buff());
		
		if(!have_skill($skill[The Ode to Booze]))
			request_buff($effect[Ode to Booze], inebriety_limit() + 10 - my_inebriety() - have_effect($effect[Ode to Booze]));
		}
	
	if(CONSUME_SCRIPT.to_lower_case() == "eatdrink.ash")
		eatdrink(fullness_limit(), inebriety_limit(), spleen_limit(), true);
	else
		cli_execute("run "+ CONSUME_SCRIPT);
		
	if(my_inebriety() <= inebriety_limit())
		failure(CONSUME_SCRIPT +" failed to overdrink");
	}

void print_summary() {
	/* Prints of summary of relevant statistics collected about your day's farming */
	announce(2, "print_summary");
	string start_adventures = get_property("_har_startadventures");
	string end_adventures = get_property("_har_endadventures");
	string start_meat = get_property("_har_startmeat");
	string end_meat = get_property("_har_endmeat");
	string ocd_profit = get_property("_har_ocd_profit");	
	int num_lucre = total_amount($item[filthy lucre]);

	announce(3, "_har_startadventures: "+start_adventures);
	announce(3, "_har_endadventures: "+end_adventures);
	announce(3, "_har_startmeat: "+start_meat);
	announce(3, "_har_endmeat: "+end_meat);
	announce(3, "_har_ocd_profit: "+ocd_profit);
	
	int turns_spent = end_adventures.to_int() - start_adventures.to_int();
	int meat_gained = end_meat.to_int() + ocd_profit.to_int() - start_meat.to_int();

	// Add data to HAR_Daily_Profit.txt
	if(get_property("_har_profit_recorded") != "true")
		{
		file_to_map("HAR_Daily_Profit_"+my_name()+".txt", statistics);
		string time_stamp = today_to_string();
		statistics [time_stamp].meat_made = meat_gained;
		statistics [time_stamp].advs_spent = turns_spent;
		map_to_file(statistics, "HAR_Daily_Profit_"+my_name()+".txt");
		set_property("_har_profit_recorded", "true");
		}
	else
		announce(3, "Profit already recorded");

	if(turns_spent > 0)
		{
		if(FARM || VMINE)
			{
			float mpa = meat_gained/turns_spent;
			
			string message = "Farming complete. You have pleased Demeter.";
			if(meat_gained < 1)
				message = "You call that a profit? Looks like somebody forgot to make a sacrifice to Demeter.";
			
			announce(1, message, true);
			print("You used "+turns_spent+" adventures", "green");
			print("You gained "+meat_gained+" meat", "green");
			print("You made "+round(mpa)+" meat per adventure", "green");
			}
		
		if(BOUNTYHUNT)
			{
			if(!have_skill($skill[Transcendent Olfaction]))
				{
				if(num_lucre == 100)
					print("Congratulations, you've got 100 lucre!", "green");
				else if(num_lucre == 150)
					print("You have 150 pieces of filthy lucre. The grind continues...", "green");
				else if(num_lucre == 190)
					print("You have 190 pieces of filthy lucre. Getting close!", "green");
				else if(num_lucre == 199)
					print("You have 199 pieces of filthy lucre. Exciting!", "green");
				else if(num_lucre == 200)
					print("You've got 200 lucre. MILESTONE!", "green");
				else
					print("You have "+ num_lucre +" pieces of filthy lucre", "green");
				}
			else 
				{
				if(num_lucre == 200)
					print("Oh come on. You've ALREADY got olfaction and yet you still felt the need to get ANOTHER 200 lucre?!", "red");
				else
					print("You have "+ num_lucre +" pieces of filthy lucre", "green");
				}
			}
			
		if(DUCKHUNT)
			{
			int num_tape = total_amount($item[duct tape]);
			print("You have "+ num_tape +" lengths of duct tape", "green");
			}
		
		print_html("<br><hr>");
		}
	else
		print("Summary could not be printed because one or more of your _har values was not properly set", "red");
	}
	
void equip_rollover_gear()
	{
	/*	Equips the most optimal rollover gear you have in your inventory and saves this as your 
		specified rollover outfit */
	announce(2, "equip_rollover_gear");	
	announce(1, "Equipping rollover gear");
	
	if(have_foldable("cheese"))
		get_foldable($item[stinky cheese diaper]);
	
	outfit(ROLLOVER_OUTFIT);
	
	maximize("adv, switch Disembodied Hand", false);
	    
    cli_execute("outfit save "+ ROLLOVER_OUTFIT);
	}

void finish_up()
	{
	/* Executes various functions to tidy up at the end of the day */
	announce(2, "finish_up");
	
	announce(1, "Finishing up for the day", true);
	
	set_property("har_current_activity", "finish");
	
	if(FINISH_UP_SCRIPT != "")
		cli_execute(FINISH_UP_SCRIPT);
	
	apply_prerun_settings();
	
	if(have_skill($skill[Rainbow Gravitation]))
		cast_rainbow_gravitation();
		
	improve_spirits();
	
	if(get_property("_har_endadventures") == "")
		set_property("_har_endadventures", my_turncount());
	
	if(finished_farming() && my_inebriety() <= inebriety_limit() && OVERDRINK)
		overdrink();
	
	if(get_property("_har_ocd_profit") == "")
		set_property("_har_ocd_profit", run_ocd());
		
	if(get_property("_har_endmeat") == "")
		set_property("_har_endmeat", my_meat() + my_closet_meat());
			
	equip_rollover_gear();
	
	take_closet(my_closet_meat());
	
	print_summary();
	}


/******************\
 Script Entry Point 
\******************/
void main()
	{
	announce(2, "main");
	set_default_settings();
	
	if(!COMPLETED_SETUP)
		{
		print("Script setup complete. You can now configure the script's options with the relay script", "green");
		print("Remember to click the Save button (bottom left) when you're done", "green");
		}
	else
		{
		announce(1, "Preparing to bring in the harvest", true);
		initialise();
		
		if(!finished_farming())
			{
			if(BOUNTYHUNT)
				{				
				if(!finished_bountyhunting())
					bountyhunteasy();
					bountyhunthard();
					bountyhuntspecial();
				}
			}
				
		preconsumption_script();
		
		if(!finished_farming())
			fill_organs();
			
		postconsumption_script();
		
		if(!finished_farming())
			{
			if(PUTTYFARM)
				copyfarm();
				
			if(DUCKHUNT)
				duck_hunt();

			if(VMINE)
				volcano_mine();
			
			if(FARM)	
				farm();
			}
		
		finish_up();
		}
	}
