/***********************************************\
				relay_Harvest
	
	    A relay script for Harvest.ash

\***********************************************/

import<htmlform.ash>
import<zlib.ash>;

/*
--Adding options--
Before proceeding, remember to add data for the option you are adding to HAR_Options.txt using the
format:
	optioname	displayedname	mouseovertext	optiondatatype

If you wish to put a sub-heading in the table (eg: Scripts, Last 7 days, Options etc.) use 
	construct_header("HEADING");

First locate the function which constructs the table for the section of the script you're interested
	eg: farming, bountyhunting, puttyfarming etc.

To make the option itself use construct_option(...)
	eg: construct_option(har_SETTINGNAME)

Two special cases: Dropdowns and radio buttons
	Dropdowns
		Enter each of the options that will be contained in the dropdown into the dropdown_items map
			eg: dropdown_items["THIS_WILL_APPEAR_IN_THE_DROPDOWN"] = "har_SETTINGNAME";
		Now use construct_option with the second parameter (special) set to "dropdown"
			eg: construct_option("har_SETTINGNAME", "dropdown");
	Radio buttons
		Currently only one setting uses radio buttons so for now this has to be done manually. See
		the bottom of general() for an example.

--Adding statistics to the stats table--
At the bottom of the stats() function choose a position for the statistic you wish to add and use
	construct_stat_row("NAME_OF_STAT", INT_VALUE_FOR_STAT)
Note that the integer you supply will be converted into a string and formatted with commas (ie: 1000
becomes 1,000)

*/


// Functions from Harvest (Harvest is too slow to import every time we want to run the relay script)
boolean is_underwater(location loc)
	{
	return loc.zone == "The Sea";
	}


// Maps
record { 
	int meat_made; 
	int advs_spent; 
}	[string] statistics;

string [string] sections;
string [string] dropdown_items; ###

record {
	string title;
	string description;
	string type;
} [string] har_options;


// Declare variables
string this_version = "2.0.5";
string default_tab = "stats";
boolean row_coloured;
string class_string;

int radio_separation = 5;
int tab_radius = 4;
int edging_radius = 6;
int table_width = 400;
int cell_height = 27;
int field_size = table_width/2-7;

string colour_dark = "#448A01";
string colour_med = "#5CBF00";
string colour_light = "#CCE3A8";
string colour_background = "#F7FAF5";

//F7FAF5

int shadow_size = 1;
int shadow_offset = 1;
string shadow_colour = "grey";

int textsize_small = 12;
int textsize_med = 15;

// Functions
boolean have_foldable(string foldable) {
	/* Returns true if you have any of the forms of the foldable related to <foldable>.
	"Putty" for spooky putty, "cheese" for stinky cheese, "origami" for naughty origami, 
	"doh" for Rain-Doh. */
	int count;
	switch (foldable) {
		case "putty":
			count += available_amount($item[spooky putty monster]);
			foreach putty_form in get_related($item[spooky putty sheet], "fold")
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
	
int total_amount(item it)
	{
	return closet_amount(it)+display_amount(it)+item_amount(it)+storage_amount(it)+equipped_amount(it);
	}
	
string repeat_char(string char, int times)
	{
	string the_string;
	for i from 1 to times
		the_string += char;
		
	return the_string;
	}

string format_number(string unformatted)
	{
	string reverse;
	string formatted;
	
	int count;
	for index from length(unformatted)-1 to 0
		{
		count += 1;
		string char = char_at(unformatted, index);
		reverse += char;
		if(count%3 == 0 && count != length(unformatted))
			reverse += ",";
		}
		
	for index from length(reverse)-1 to 0
		formatted += char_at(reverse, index);
	
	return formatted;
	}

void write_styles()
	{
	writeln("<style type='text/css'>"+			
			"body {"+
			"text-align:center;"+
			"padding:0;"+
			"cursor:default;"+
			"user-select: none;"+
			"-webkit-user-select: none;"+
			"-moz-user-select: text;}"+
			
			"heading {"+
				"font-family:times;"+
				"font-size:500%;"+
				"color:"+ colour_dark +";}"+
			
			"tagline {"+
				"font-size:90%;"+
				"font-style:italic;}"+
			
			"tab_bar {"+
				"font:"+ textsize_med +"px times;"+
				"color:white;"+
				"text-shadow:0px 0px 2px black;"+
				"padding-top:15px;"+
				"padding-bottom:1px;}"+
						
			"tab {"+
				"background-color:"+ colour_light +";"+
				"position:relative;"+
				"box-shadow:"+ shadow_offset +"px "+ shadow_offset +"px "+ shadow_size +"px "+ shadow_colour +";"+
				"margin-left:1px;"+
				"margin-right:1px;"+
				"padding:1px 5px;"+
				"cursor:pointer;"+
				"border:1px solid "+ colour_dark +";"+
				"border-radius:"+ tab_radius +"px;"+
				"-webkit-border-radius:"+ tab_radius +"px;"+
				"-moz-border-radius:"+ tab_radius +"px;}"+

			"tab:hover {background-color:"+ colour_med +";}"+
			
			//"tab:active {background-color:"+ colour_dark +";}"+
			
			".tab_hop {"+
				"animation:hop 0.3s;"+
				"-webkit-animation:hop 0.3s;"+
				"-moz-animation:hop 0.3s;}"+
			
			"@keyframes hop {"+
				"0%   {top:0px;}"+
				"30%   {top:-5px;}"+
				"60%   {top:0px;}"+
				"80%   {top:-2px;}"+
				"100% {top:0px;}}"+
			
			"@-webkit-keyframes hop {"+
				"0%   {top:0px;}"+
				"30%   {top:-5px;}"+
				"60%   {top:0px;}"+
				"80%   {top:-2px;}"+
				"100% {top:0px;}}"+
			
			"@-moz-keyframes hop {"+
				"0%   {top:0px;}"+
				"30%   {top:-5px;}"+
				"60%   {top:0px;}"+
				"80%   {top:-2px;}"+
				"100% {top:0px;}}"+
			
			"table {"+
				"font:"+ textsize_small +"px helvetica;"+
				"text-align:center;"+
				"display:none;"+
				"box-shadow:"+ shadow_offset +"px "+ shadow_offset +"px "+ shadow_size +"px "+ shadow_colour +";"+
				"border-collapse:collapse;"+
				"width:"+ table_width +"px;"+
				"margin-left:auto;"+
				"margin-right:auto;}"+
				
			"table.invisible {"+
				"display:block;"+
				"border:hidden;"+
				"margin-bottom:10px;"+
				"box-shadow:0px 0px 0px;}"+
				
			"div {"+
				"position:relative;"+
				"background-color:"+ colour_background +";"+
				"border-shadow:"+ shadow_offset +"px "+ shadow_offset +"px "+ shadow_size +"px "+ shadow_colour +";"+
				"margin-left:auto;"+
				"margin-right:auto;"+
				"margin-top:-"+ (10+edging_radius) +"px;"+
				"padding-top:"+ (15+edging_radius) +"px;"+
				"display:block;"+
				"font:"+ textsize_med +"px times;"+
				"box-shadow:0px 0px 0px;}");
			
	writeln("th {"+
				"font-weight:bold;"+
				"color:white;"+
				"border:1px solid "+ colour_dark +";"+
				"background:"+ colour_med +"}"+
				
			"tr {"+
				"background-color:white;"+
				"border:1px solid "+ colour_dark +";}"+
				
			"tr.alt {"+
				"background-color:"+ colour_light +";}"+
				
			"td {"+
				"border:1px solid "+ colour_dark +";"+
				"position:relative;"+
				"height:"+ cell_height +"px;"+
				"width:"+ table_width/2 +"px;}"+
									
			"save_text {"+
				"font:"+ textsize_med +"px times;"+
				"color:"+ colour_dark +";"+
				"text-align:center}"+
				
			"</style>");
	}
	
string change_visibility(string id, string action)
	{
	if(id == "current")
		return "document.getElementById('panel_'+ getCookie('active')).style.display='"+ action +"';";
	
	return "document.getElementById('"+ id +"').style.display='"+ action +"';";
	}
	
string set_background(string id, string colour)
	{
	if(colour == "reset")
		{
		if(id == "current")
			return "document.getElementById('tab_'+ getCookie('active')).style.background='';";
		
		return "document.getElementById('"+ id +"').style.background='';";
		}
	
	if(id == "current")
		return "document.getElementById('tab_'+ getCookie('active')).style.background='"+ colour +"';";
	
	return "document.getElementById('"+ id +"').style.background='"+ colour +"';";
	}
	
string set_focus(string id)
	{
	string panel_id = "panel_"+ id;
	string tab_id = "tab_"+ id;
		
	return 
		change_visibility("current", "none")+
		set_background("current", "reset")+
		change_visibility(panel_id, "block")+ 
		set_background(tab_id, colour_dark)+
		"getElementById('tab_'+ getCookie('active')).className='';"+
		"setCookie('active','"+ id +"',365);";
	}
	
string description(string the_setting)
	{
	return har_options[the_setting].description;
	}
	
string title(string the_setting)
	{
	return har_options[the_setting].title;
	}
	
string row_colour()
	{
	/* Returns the appropraite class string for the current row colour and switches the row_coloured 
		boolean */
	if(row_coloured)
		{
		row_coloured = false;
		return " class='alt'";
		}
	
	row_coloured = true;
	return "";
	}
	
void construct_option(string the_setting, string special)
	{
	// $datatype[none] is not recognised as a valid entry so we have to do some tedious checking
	
	string type = har_options[the_setting].type;
	string label = the_setting +" setting";
	string current_setting = getvar(the_setting);
	string placeholder;
		
	writeln("<tr"+ row_colour() +"><td title='"+ description(the_setting) +"'>"+ title(the_setting) +"</td><td>");
	
	if($strings[int, boolean, property] contains type)
		attr("style='width:"+ field_size +"px;'");
		
	if(special == "dropdown")
		{
		attr("style='width:"+ (table_width/2-4) +"px;'");
		
		if(type == "string")
			vars[the_setting] = write_select(getvar(the_setting), the_setting +" setting", "");
		else if(type == "effect")
			vars[the_setting] = write_select(getvar(the_setting).to_effect(), the_setting +" setting", "");
		
		// First option will always be none
		if(type == "string")	
			write_option("none");
		else if(type == "effect")
			write_option($effect[none]);
		
		// Now construct the other options
		foreach key in dropdown_items
			{
			if(dropdown_items[key] == the_setting)	
				{
				if(type == "string")	
					write_option(key);
				else if(type == "effect")
					write_option(key.to_effect());
				}
			}
		}
	else
		{
		if(type == "boolean")
			vars[the_setting] = write_check(current_setting.to_boolean(), label, "");
		else if(type == "int")
			vars[the_setting] = write_field(current_setting, label, "");
		else if(type == "property")
			set_property(the_setting, write_field(get_property(the_setting), label, ""));
		else
			{
			if(type == "string")
				placeholder = "None";
			else if(type == "familiar")
				{
				placeholder = "Familiar";
				if(current_setting != "none")
					current_setting = current_setting.to_familiar();
				}
			else if(type == "item")
				{
				placeholder = "Item";
				if(current_setting != "none")
					current_setting = current_setting.to_item();
				}
			else if(type == "location")
				{
				placeholder = "Location";
				if(current_setting != "none")
					current_setting = current_setting.to_location();
				}
			else if(type == "monster")
				{
				placeholder = "Monster";
				if(current_setting != "none")
					current_setting = current_setting.to_monster();
				}
			else
				abort("Invaild option type specified for setting '"+ the_setting +"': "+ type);
			
			attr("style='width:"+ field_size +"px;' placeholder='"+ placeholder +"'");
			vars[the_setting] = write_field(current_setting, label, "");
			}
		}

	writeln("</td></tr>");
	
	if(special == "dropdown")
		finish_select();
	}
	
void construct_option(string the_setting)
	{
	construct_option(the_setting, "");
	}

void construct_header(string header)
	{
	writeln("<tr><th colspan='2'>"+ header +"</th></tr>");
	if(row_coloured)
		row_coloured = false;
	}



// Elements
	
void tab_bar()
	{
	writeln("<tab_bar>");
	
	sections ["stats"] = "Statistics";
	sections ["gen"] = "General";
	sections ["bounty"] = "Bounty Hunting";
	sections ["putty"] = "Copy Farming";
	sections ["duck"] = "Duck Hunting";
	sections ["vmine"] = "Volcano Mining";
	sections ["farm"] = "Farming";
	sections ["roll"] = "Rollover";
	
	void make_tab(string id)
		{
		string title = sections[id];
		string tab_id = "tab_"+ id;
		string special = "document.getElementById('save').style.visibility='';";
		if(id == "stats")
			special = "document.getElementById('save').style.visibility='hidden';";
		writeln('<tab id="'+ tab_id +'" onclick="if(\'tab_\'+getCookie(\'active\')!=this.id) this.className=\'tab_hop\';'+ special + set_focus(id) +'">'+ title +'</tab>');
		}
	
	make_tab("stats");
	make_tab("gen");
	make_tab("bounty");
	make_tab("putty");
	make_tab("duck");
	make_tab("vmine");
	make_tab("farm");
	make_tab("roll");

	writeln("</tab_bar>");
	}

void stats()
	{	
	file_to_map("HAR_Daily_Profit_"+my_name()+".txt", statistics);
	int weekly_profit;
	int total_profit;
	int highest_profit;
	int lowest_profit = 999999999;
	int time_period = 7; // Number of days in a 'week' (sets time period for short-term analysis)
	int weekly_turns_spent;
	int total_turns_spent;
	int days = count(statistics);
	int actual_time_period = min(7, days); // <time_period> can't be greater than the number of day's worth of data
	int count;
	foreach day in statistics
		{
		count += 1;
		int profit = statistics[day].meat_made;
		int turns_spent = statistics[day].advs_spent;
		
		if(count > days-time_period) // Don't be tempted to change this to <actual_time_period>
			{
			weekly_profit += profit;
			weekly_turns_spent += max(0, turns_spent);
			}

		total_profit += profit;
		highest_profit = max(profit, highest_profit);
		lowest_profit = min(profit, lowest_profit);
		
		total_turns_spent += max(0, turns_spent);
		}
	
	// Weekly
	int weekly_av_mpa;
	if(weekly_turns_spent != 0)
		weekly_av_mpa = round(weekly_profit/weekly_turns_spent);
	
	int weekly_av_mpd;
	if(actual_time_period != 0)
		weekly_av_mpd = round(weekly_profit/actual_time_period);
	
	// All time
	if(lowest_profit == 999999999) // Because Worst day: 999999999 looks stupid
		lowest_profit = 0;
	
	int av_mpa;
	if(total_turns_spent != 0)
		av_mpa = round(total_profit/total_turns_spent);
	
	int av_mpd;
	if(days != 0)
		av_mpd = round(total_profit/days);
	
	// Daily
	int start_adventures = get_property("_har_startadventures").to_int();
	int end_adventures = get_property("_har_endadventures").to_int();
	int start_meat = get_property("_har_startmeat").to_int();
	int end_meat = get_property("_har_endmeat").to_int();
	int ocd_profit = get_property("_har_ocd_profit").to_int();
	
	int turns_today = max(0, end_adventures - start_adventures);
	int meat_gained_today = end_meat - start_meat + ocd_profit;
	
	// If we're still farming, don't show a negative (or otherwise inaccurate) number
	if(meat_gained_today < 0 && end_meat == 0)
		meat_gained_today = 0;
	
	// Just in case we end up with a division by 0
	boolean result = false;
	int mpa_today;
	if(turns_today != 0)
		mpa_today = round(meat_gained_today/turns_today);
	
	void construct_stat_row(string name, int value)
		{
		writeln("<tr"+ row_colour() +"><td>"+ name +"</td><td>"+ format_number(value) +"</td></tr>");
		}
	
	writeln("<table id='panel_stats'>");
		// Today
		construct_header("Today");
		construct_stat_row("Turns", turns_today);
		construct_stat_row("Meat per adventure", mpa_today);
		construct_stat_row("Meat made", meat_gained_today);
		
		// Weekly
		construct_header("Last "+ actual_time_period +" Days");
		construct_stat_row("Average meat per adventure", weekly_av_mpa);
		construct_stat_row("Average meat per day", weekly_av_mpd);
		construct_stat_row("Meat made", weekly_profit);

		// All time
		construct_header("All Time");
		construct_stat_row("Days", days);
		construct_stat_row("Turns", total_turns_spent);
		construct_stat_row("Best day", highest_profit);
		construct_stat_row("Worst day",  lowest_profit);
		construct_stat_row("Average meat per adventure", av_mpa);
		construct_stat_row("Average meat per day", av_mpd);
		construct_stat_row("Meat made", total_profit);
		
		writeln("</table>");
	}

void general()
	{	
	writeln("<table id='panel_gen'>");
	
	// Scripts
	construct_header("Scripts");
	construct_option("har_gen_ccs");
	construct_option("har_gen_bbs");
	construct_option("har_gen_preconsumption_script");
	construct_option("har_gen_consume_script");
	construct_option("har_gen_postconsumption_script");
	construct_option("har_gen_finish_up_script");		
		
		
	// Effects
	construct_header("Effects");
	
	// Island concert effect
	dropdown_items["Moon'd"] = "har_gen_concert_effect";
	dropdown_items["Dilated Pupils"] = "har_gen_concert_effect";
	dropdown_items["Optimist Primal"] = "har_gen_concert_effect";
	dropdown_items["Elvish"] = "har_gen_concert_effect";
	dropdown_items["Winklered"] = "har_gen_concert_effect";
	dropdown_items["White-boy Angst"] = "har_gen_concert_effect";
	construct_option("har_gen_concert_effect", "dropdown");
	
	// Demon
	dropdown_items["Preternatural Greed"] = "har_gen_demon_to_summon";
	dropdown_items["Fit to be Tide"] = "har_gen_demon_to_summon";
	dropdown_items["Big Flaming Whip"] = "har_gen_demon_to_summon";
	dropdown_items["Demonic Taint"] = "har_gen_demon_to_summon";
	dropdown_items["Burning, Man"] = "har_gen_demon_to_summon";
	#dropdown_items["The Pleasures of the Flesh"] = "har_gen_demon_to_summon";
	dropdown_items["Existential Torment"] = "har_gen_demon_to_summon";
	dropdown_items["pies"] = "har_gen_demon_to_summon";
	dropdown_items["drinks"] = "har_gen_demon_to_summon";
	construct_option("har_gen_demon_to_summon", "dropdown");
	
	// Friars
	dropdown_items["familiar"] = "har_gen_friar_blessing";
	dropdown_items["food"] = "har_gen_friar_blessing";
	dropdown_items["booze"] = "har_gen_friar_blessing";
	construct_option("har_gen_friar_blessing", "dropdown");

	// Hatter
	dropdown_items["Dances with Tweedles"] = "har_gen_hatter_buff";
	dropdown_items["Quadrilled"] = "har_gen_hatter_buff";
	construct_option("har_gen_hatter_buff", "dropdown");
	
	if(total_amount($item[Clan VIP Lounge key]) > 0)
		{
		// Pool
		dropdown_items["aggressive"] = "har_gen_pool_style";
		dropdown_items["strategic"] = "har_gen_pool_style";
		dropdown_items["stylish"] = "har_gen_pool_style";
		construct_option("har_gen_pool_style", "dropdown");
		}


	// Other
	construct_header("Other");
	construct_option("har_gen_sugarshields");
	construct_option("har_gen_dosemirares");
	construct_option("har_gen_buy_recordings");
	construct_option("har_gen_overdrink");
	construct_option("valueOfAdventure");
	
	writeln("<tr"+ row_colour() +"><td title='"+ description("har_gen_verbosity") +"'>"+ title("har_gen_verbosity") +"</td><td>");
	attr("title='Be silent'");
	vars["har_gen_verbosity"] = write_radio(getvar("har_gen_verbosity").to_int(), "verbosity", " 0", 0);
	writeln(repeat_char("&nbsp", radio_separation));
	attr("title='Be moderately informative'");
	write_radio(getvar("har_gen_verbosity").to_int(), "verbosity", " 1", 1);
	writeln(repeat_char("&nbsp", radio_separation));
	attr("title='Print function names'");
	write_radio(getvar("har_gen_verbosity").to_int(), "verbosity", " 2", 2);
	writeln(repeat_char("&nbsp", radio_separation));
	attr("title='Report everything'");
	vars["har_gen_verbosity"] = write_radio(getvar("har_gen_verbosity").to_int(), "verbosity", " 3", 3);
	
	if(getvar("har_farming_location") == "giant's castle (top floor)")
		construct_option("har_gen_defaultocd");
	writeln("</td></tr>");
	
	writeln("</table>");
	}
	
void bountyhunting()
	{
	writeln("<table id='panel_bounty'>");
	construct_header("Options");
		
	construct_option("har_bountyhunt_easy");
	construct_option("har_bountyhunt_hard");
	construct_option("har_bountyhunt_special");
	construct_option("har_bountyhunting_outfit");
	construct_option("har_bountyhunting_fam");
	construct_option("har_bountyhunting_famequip");
	construct_option("har_bountyhunting_mood");
	if(have_foldable("putty") || have_foldable("doh"))
		construct_option("har_bountyhunting_putty");
		
	writeln("</table>");
	}	

void copyfarming()
	{
	writeln("<table id='panel_putty'>");
	construct_header("Options");
	
	if(have_foldable("putty") || have_foldable("doh"))
		{
		construct_option("har_puttyfarm");
		construct_option("har_puttyfarming_outfit");
		construct_option("har_puttyfarming_fam");
		construct_option("har_puttyfarming_famequip");
		construct_option("har_puttyfarming_mood");
		}
	else
		writeln("<tr"+ row_colour() +"><td colspan='2'>You don't have any spooky putty</td></tr>");
		
	writeln("</table>");
	}

void duckhunting()
	{
	writeln("<table id='panel_duck'>");
	construct_header("Options");
		
	if(my_level() >= 12)
		{
		construct_option("har_duckhunt");
		construct_option("har_duckhunting_outfit");
		construct_option("har_duckhunting_fam");
		construct_option("har_duckhunting_famequip");
		construct_option("har_duckhunting_mood");
		}
	else
		writeln("<tr"+ row_colour() +"><td colspan='2'>You must be at least level 12 to duck hunt</td></tr>");
		
	writeln("</table>");
	}

void volcanomining()
	{
	writeln("<table id='panel_vmine'>");
	construct_header("Options");

	if((get_property("hotAirportAlways") == "true") || (get_property("_hotAirportToday") == "true"))
		{
		construct_option("har_vmine");
		construct_option("har_vmining_lazy_mine");
		construct_option("har_vmining_auto_detection");
		construct_option("har_vmining_outfit");
		construct_option("har_vmining_adventure_limit");
		}
	else
		writeln("<tr"+ row_colour() +"><td colspan='2'>You don't have access to That 70s Volcano</td></tr>");

	writeln("</table>");
	}

void farming()
	{
	writeln("<table id='panel_farm'>");
	construct_header("Options");
		
	construct_option("har_farm");
	if(is_underwater(getvar("har_farming_location").to_location()))
		construct_option("har_farming_sea_hat");
	construct_option("har_farming_outfit");
	construct_option("har_farming_fam");
	construct_option("har_farming_famequip");
	construct_option("har_farming_mood");
	construct_option("har_farming_location");
	if(have_skill($skill[Transcendent Olfaction]))	
		{
		construct_option("har_farming_olfacted_monster");

		if(have_foldable("putty") || have_foldable("doh"))
			construct_option("har_farming_putty_olfacted");
		}
	
	if(my_class() == $class[disco bandit])
		construct_option("har_farming_disco_combos");
		
	writeln("</table>");
	}

void do_rollover()
	{
	writeln("<table id='panel_roll'>");
	construct_header("Options");
		
	construct_option("har_rollover_outfit");
		
	writeln("</table>");
	}

void save_button()
	{
	writeln("<table class='invisible' style='text-align:left; position:relative; top:"+ (shadow_size+2) +"px; right:3px;'><tr style=' background-color:"+ colour_background +";'><td id='save' style='border:solid "+ colour_background +"; width:"+ table_width +"px;'>");
	
	if(write_button("save", "Save"))
		{
		writeln("<style type='text/css'>"+
			"div.edging {"+
				"width:800px;"+
				"border-radius:25px;"+
				"border:2px solid "+ colour_dark +";"+
				"border-radius:"+ edging_radius +"px;"+
				"-webkit-border-radius:"+ edging_radius +"px;"+
				"-moz-border-radius:"+ edging_radius +"px;</style>");

		writeln("<save_text>"+ repeat_char("&nbsp", 18) +"Settings saved at "+ now_to_string("h:mm a, ss") +"s</save_text>");
		if(!getvar("har_gen_completed_setup").to_boolean())
			vars["har_gen_completed_setup"] = true;
		updatevars();
		}
	else
		writeln("<style type='text/css'>"+
			"div.edging {"+
				"width:800px;"+
				"border-radius:25px;"+
				"border:2px solid "+ colour_dark +";"+
				"border-radius:"+ edging_radius +"px;"+
				"-webkit-border-radius:"+ edging_radius +"px;"+
				"-moz-border-radius:"+ edging_radius +"px;"+
			
				"animation:drop 0.7s;"+
				"-webkit-animation:drop 0.7s;"+
				"-moz-animation:drop 0.7s;"+
				"animation-timing-function:linear;"+
				"-moz-animation-timing-function:linear;"+
				"-webkit-animation-timing-function:linear;}"+
			
			"@keyframes drop {"+
				"0%   {top:-750px;}"+
				"60%   {top:0px;}"+
				"70%   {top:-8px;}"+
				"80%   {top:0px;}"+
				"90%   {top:-3px;}"+
				"100% {top:0px;}}"+
			
			"@-webkit-keyframes drop {"+
				"0%   {top:-750px;}"+
				"60%   {top:0px;}"+
				"70%   {top:-8px;}"+
				"80%   {top:0px;}"+
				"90%   {top:-3px;}"+
				"100% {top:0px;}}"+
				
			"@-moz-keyframes drop {"+
				"0%   {top:-750px;}"+
				"60%   {top:0px;}"+
				"70%   {top:-8px;}"+
				"80%   {top:0px;}"+
				"90%   {top:-3px;}"+
				"100% {top:0px;}}"+
		
			"</style></td></tr></table>");
	}

void main()
	{
	// Setup
	setvar("har_gen_completed_setup", false);
	if(!getvar("har_gen_completed_setup").to_boolean())
		cli_execute("run Harvest.ash");
	
	//Load maps
	file_to_map("HAR_Options.txt", har_options);
	
	// Construct the page
	write_page();
	
	write_styles();

	// Heading, tagline	and initialise JS vars
	writeln("<body align='center'>"+
		"<script language=Javascript>"+
		"function setCookie(c_name,value,exdays) {"+
			"var exdate=new Date();"+
			"exdate.setDate(exdate.getDate() + exdays);"+
			"var c_value=escape(value) + ((exdays==null) ? '' : '; expires='+exdate.toUTCString());"+
			"document.cookie=c_name + '=' + c_value;}"+
		
		"function getCookie(name) {"+
			"var nameEQ = name + '=';"+
			"var ca = document.cookie.split(';');"+
			"for(var i=0;i < ca.length;i++) {"+
				"var c = ca[i];"+
				"while (c.charAt(0)==' ') c = c.substring(1,c.length);"+
				"if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);}"+
			"return null;}"+
							
		"if (getCookie('active') == null) setCookie('active', 'gen', 365);"+
		"</script>"+
		
		"<div class='edging'>"+
		"<heading>Harvest</heading><br />"+
		"<tagline>Prepare thy work without, and make it fit for thyself in the field; and afterwards build thine house - Proverbs 24:27</tagline><br /><br />");
	
	// Signal update
	string update_message = check_version("relay_Harvest", "HAR_Relay", this_version, 7015);
	if(update_message != "")
		writeln(update_message +"<br /><br />");
	
	tab_bar();
	
	writeln("<br /><br />");
	
	stats();
	general();
	bountyhunting();
	copyfarming();
	duckhunting();
	volcanomining();
	farming();
	do_rollover();
	save_button();
	
	// Set the active tab
	writeln("<script language=Javascript>"+
		"if(getCookie('active') == 'stats') document.getElementById('save').style.visibility='hidden';"+
		change_visibility("current", "block")+
		set_background("current", colour_dark)+
		"</script>");
		
	
	writeln("</div>");
	
	finish_page();
	}
