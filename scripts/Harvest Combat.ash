/***********************************************\
				  Harvest Combat
	
     A combat script to accompany Harvest.ash

\***********************************************/


import <zlib.ash>;

check_version("Harvest Combat", "HAR_Combat", "1.2.5", 7015);

string activity = get_property("har_current_activity");
item bounty_item = get_property("currentBountyItem").to_item();
if(get_property("_har_nemesis_completed") == "")
	set_property("_har_nemesis_completed", contains_text(visit_url("questlog.php?which=2"),"has fallen beneath your mighty assault"));
boolean nemesis_completed = get_property("_har_nemesis_completed").to_boolean();
buffer mac;  // macro in progress


// Code copied from Harvest.ash (we don't want to have to import that before every combat)
record { 
	float normal_length;
	float olfacted_length;
	float savings_per_copy;
	float savings_per_5_cm; // +ve means more combats, -ve means fewer
}	[location] bounty_info;
file_to_map("HAR_Bounty_Data.txt", bounty_info);

int VERBOSITY = vars["har_gen_verbosity"].to_int();
boolean BOUNTYHUNT_WITH_PUTTY = vars["har_bountyhunting_putty"].to_boolean();
boolean PUTTY_OLFACTED = vars["har_farming_putty_olfacted"].to_boolean();
location FARMING_LOCATION = vars["har_farming_location"].to_location();
monster OLFACTED_MONSTER = vars["har_farming_olfacted_monster"].to_monster(); // The monster to olfact
boolean DANCE_COMBOS = vars["har_farming_disco_combos"].to_boolean();

void announce(int verbosity_level, string message, boolean header)
	{
	string colour;
	switch (verbosity_level)
		{
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
	
	if(verbosity_level <=  VERBOSITY)
		{
		if(header)
			print("");
		print(message, colour);
		if(header)	
			print_html("<hr>");
		}
	}
	
void announce(int verbosity_level, string message)
	{
	announce(verbosity_level, message, false);
	}

void apply_prerun_settings()
	{
	set_property("currentMood", get_property("har_prerun_mood"));
	set_property("battleAction", get_property("har_prerun_battleAction")); 
	set_property("customCombatScript", get_property("har_prerun_ccs"));
	set_property("betweenBattleScript", get_property("har_prerun_bbs"));
	set_property("counterScript", get_property("har_prerun_counterscript"));
	set_auto_attack(get_property("har_prerun_autoattack").to_int());
	}

void failure(string message)
	{
	apply_prerun_settings();
	abort(message);
	}

boolean have_foldable(string foldable) {
	/* Returns true if you have any of the forms of the foldable related to <foldable>.
	"Putty" for spooky putty, "cheese" for stinky cheese, "origami" for naughty origami.*/
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


// General functions
item stasis_item()
	{
	item stasis_item;
	if(item_amount($item[fat stacks of cash]) > 0)
		stasis_item = $item[fat stacks of cash];
	else if(item_amount($item[facsimile dictionary]) > 0)
		stasis_item = $item[facsimile dictionary];
	else if(item_amount($item[dictionary]) > 0)
		stasis_item = $item[dictionary];
	else if(item_amount($item[spices]) > 0)
		stasis_item = $item[spices];
	else if(item_amount($item[seal tooth]) > 0)
		stasis_item = $item[seal tooth];
	else if(item_amount($item[spectre scepter]) > 0)
		stasis_item = $item[spectre scepter];
	return stasis_item;
	}

string first_available_copier() {
	/* Returns as a string the first available monster-copying item in your inventory */
	announce(2, "first_available_copier");
	
	if (available_amount($item[Spooky Putty sheet]) > 0 && get_property("spookyPuttyCopiesMade").to_int() < 5)
		return "spooky putty sheet";
	else
		return "rain-doh black box";
	}

void main(int round, string opponent, string text)
	{   
	string macro(string mac) // ASH function for submitting a macro   
		{  
		announce(3, mac);
		announce(3, url_encode(mac));
		return visit_url("fight.php?action=macro&macrotext="+url_encode(mac), true, true);   
		}

	int stasis_item = stasis_item().to_int();
	if(stasis_item < 0)
		failure("You have no stasis item available!");

 	// If we're farming or using a hobo monkey we'll want to handle pickpocketing slightly differently
 	if(activity != "farm" || my_familiar() != $familiar[Hobo Monkey])
		mac.append('pickpocket; ');
	
	if(activity == "puttyfarm")
		{
		if(copies_available() == 0) // This should never happen, but in case it does, don't lose the trapped monster
			failure("You ran out of monster copies. If you want to keep this monster trapped in your putty/doh wait until you have more monster copies available after rollover");
		else	
			mac.append('use '+ first_available_copier() +'; ');
		}
	
	if(activity == "bountyhunt")
		{
		announce(3, "Beginning bountyhunting...");
		bounty easy_bounty_item = get_property("currentEasyBountyItem").to_bounty();
		bounty hard_bounty_item = get_property("currentHardBountyItem").to_bounty();
		bounty special_bounty_item = get_property("currentSpecialBountyItem").to_bounty();
		boolean is_bounty_monster = false;
		if(opponent.to_monster() == easy_bounty_item.monster || opponent.to_monster() == hard_bounty_item.monster || opponent.to_monster() == special_bounty_item.monster)
			is_bounty_monster = true;
		
		// Use spooky putty if advisable
		if(BOUNTYHUNT_WITH_PUTTY)
			{
			if(copies_available() == 0)
				announce(3, "You're out of monster copies for today so putty/doh was not used");
			else
				{
				if(!have_monster_copier())
					failure("No putty!");
				if(is_bounty_monster)
					mac.append('use '+ first_available_copier() +'; ');
				else
					announce(3, "It's not worth using your putty or doh on that monster");
				
				if(opponent.to_monster() == easy_bounty_item.monster) {
					announce(3, "Bounty item: " + easy_bounty_item);
				} else if (opponent.to_monster() == hard_bounty_item.monster) {
					announce(3, "Bounty item: " + hard_bounty_item);
				} else if (opponent.to_monster() == special_bounty_item.monster) {
					announce(3, "Bounty item: " + special_bounty_item);
				}
				announce(3, "is_bounty_monster: "+ is_bounty_monster);
				}
			}
			
		// Olfact the monster if you can, and if it drops your bounty item
		if(have_skill($skill[Transcendent Olfaction]) && have_effect($effect[On the Trail]) == 0
				&& (opponent.to_monster() == easy_bounty_item.monster || opponent.to_monster() == hard_bounty_item.monster || opponent.to_monster() == special_bounty_item.monster))
			mac.append('skill transcendent olfaction; ');
		else
			announce(3, "That monster doesn't drop your bounty item so it was not olfacted");
		}

	if(activity == "duckhunt")
		{
		announce(3, "Beginning duck hunting...");
		// Stasis with scepter if using hobo monkey - Pickpocket safety-netted in case of meat steal on the first round
		if(my_familiar() == $familiar[Hobo Monkey])
			mac.append('if !match "climbs up and sits"; pickpocket; endif; while !match "climbs up and sits" && !pastround 25s; use '+ stasis_item +'; endwhile;');   
		else
			mac.append('pickpocket; ');
			
		// Stasis with scepter until round 25 if using mimiclike familiar
		if(my_familiar() == $familiar[Stocking Mimic] || my_familiar() == $familiar[Cocoabo] ||my_familiar() == $familiar[Ninja Pirate Zombie Robot])
			mac.append('while !pastround 25; use '+ stasis_item +'; endwhile;'); 
		}


	if(activity == "farm")
		{
		announce(3, "Beginning farming...");
		// Stasis with scepter if using hobo monkey - Pickpocket safety-netted in case of meat steal on the first round
		if(my_familiar() == $familiar[Hobo Monkey])
			mac.append('if !match "climbs up and sits"; pickpocket; endif; while !match "your shoulder, and hands you some meat" && !pastround 25s; use '+ stasis_item +'; endwhile;');   
		else
			mac.append('pickpocket; ');
			
		// Stasis with scepter until round 25 if using mimiclike familiar
		if(my_familiar() == $familiar[Stocking Mimic] || my_familiar() == $familiar[Cocoabo] ||my_familiar() == $familiar[Ninja Pirate Zombie Robot])
			mac.append('while !pastround 25; use '+ stasis_item +'; endwhile;'); 
				
		// Olfaction
		if(OLFACTED_MONSTER != $monster[none] && opponent.to_monster() == OLFACTED_MONSTER)
			{
			// Sniff the monster if you're not on the trail
			if(have_effect($effect[On the Trail]) == 0)
				mac.append('skill transcendent olfaction; ');
				
			if(PUTTY_OLFACTED && !have_copied_monster())
				{
				announce(3, "Copying sniffed monster");
				if(!have_monster_copier())
					failure("You don't have a putty sheet or rain-doh box available, that shouldn't have happened");
				
				if(copies_available() > 0)
					mac.append('use '+ first_available_copier() +'; ');
				else
					announce(3, "The sniffed monster wasn't puttied because you're out of putties");
				}
			
			}
		
		// Summon hobo
		if(have_equipped($item[Hodgman's porkpie hat]) && have_equipped($item[Hodgman's lobsterskin pants]) && have_equipped($item[Hodgman's bow tie]))  
			mac.append("if hasskill 7052; skill 7052; endif; if hasskill 7048; skill 7048; endif; if hasskill 7050; skill 7050; endif;");
		
		// DB combos
		if(DANCE_COMBOS && my_class() == $class[Disco Bandit])
			{
			announce(3, "Beginning db combos...");
			boolean can_rave, can_dnirvana, can_dconcentration;
			
			string disco_nirvana = "skill 5005; skill 5008;";
			string disco_concentration = "skill 5003; skill 5005; skill 5008;";
			
			string [string] rave;
			
			// Disco combos
			if(have_skill($skill[Disco Dance of Doom]) && have_skill($skill[Disco Dance II: Electric Boogaloo]))
				{
				can_dnirvana = true;
				
				if(have_skill($skill[Disco Eye-Poke]))
					can_dconcentration = true;
				}
			
			announce(3, "can_dnirvana: "+ can_dnirvana);
			announce(3, "can_dconcentration: "+ can_dconcentration);
			
			// Rave combos
			if(have_skill($skill[Break It On Down]) && 
				have_skill($skill[Pop and Lock It]) && 
				have_skill($skill[Run Like the Wind]) &&
				nemesis_completed)
				{
				can_rave = true;
				announce(3, "can_rave: "+ can_rave);
				
				rave["steal"] = get_property("raveCombo5");
				rave["concentration"] = get_property("raveCombo1");
				rave["nirvana"] = get_property("raveCombo2");
				
				foreach combo in rave
					{
					string the_skills = rave[combo];
					
					if(the_skills != "")
						{
						int first_comma = index_of(the_skills, ",");
						int last_comma = last_index_of(the_skills, ",");
						
						announce(3, "combo: "+ combo);
						announce(3, "first_comma: "+ first_comma);
						announce(3, "last_comma: "+ last_comma);
						announce(3, "the_skills: "+ the_skills);
						
						string skill1 = "skill "+ substring(the_skills, 0, first_comma) +"; ";
						string skill2 = "skill "+ substring(the_skills, first_comma+1, last_comma) +"; ";
						string skill3 = "skill "+ substring(the_skills, last_comma+1) +"; ";
						
						rave[combo] = (skill1+skill2+skill3);
						announce(3, "rave[combo]: "+ rave[combo]);
						}
					}				
				}
				
			// Choose most optimal(ish) order for combos
			if(can_rave) mac.append(rave["steal"]);
			
			if(FARMING_LOCATION == $location[The Castle in the Clouds in the Sky (Top Floor)]) // Prioritise +meat combos
				{
				if(can_rave) mac.append(rave["nirvana"]);
				if(can_dnirvana) mac.append(disco_nirvana);
				if(can_rave) mac.append(rave["concentration"]);
				if(can_dconcentration) mac.append(disco_concentration);
				}
			else // Probably item farming so prioritise +item combos
				{
				if(can_rave) mac.append(rave["concentration"]);
				if(can_dconcentration) mac.append(disco_concentration);	
				if(can_rave) mac.append(rave["nirvana"]);
				if(can_dnirvana) mac.append(disco_nirvana);
				}
			}		
		}

	// Finish the fight
	mac.append('while !pastround 25; attack; endwhile;');

	// Finally, submit the macro
	macro(mac); 
	}