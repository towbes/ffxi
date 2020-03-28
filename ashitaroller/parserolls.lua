function parse_rolls(packet_data)--returns roll_name, roll_value(when a roll is rolled or double-upped)
	local r_name;
	local r_value;
	local my_player_id 		= AshitaCore:GetDataManager():GetParty():GetMemberServerId(0);
	local act           = { };
	act.actor_id        = ashita.bits.unpack_be( packet_data, 40, 32 );
	act.target_count    = ashita.bits.unpack_be( packet_data, 72, 8 );
	act.category        = ashita.bits.unpack_be( packet_data, 82, 4 );

	act.param           = ashita.bits.unpack_be( packet_data, 86, 10 );                   --will be the spell a mob is casting, if actor_id is not the player_id etc.. this is not the spellId for when a player is casting
	act.recast          = ashita.bits.unpack_be( packet_data, 118, 10 );                  --this will have a value when the player resolves a spell, not sure about others
	act.unknown         = 0;
	act.targets         = { };
	local bit           = 150;
	for i = 1, act.target_count do
		act.targets[i]              = { };
		act.targets[i].id           = ashita.bits.unpack_be( packet_data, bit, 32 );
		act.targets[i].action_count = ashita.bits.unpack_be( packet_data, bit + 32, 4 );
		act.targets[i].actions      = { };
		for j = 1, act.targets[i].action_count do-- Loop and fill action data..
			act.targets[i].actions[j]           = { };
			act.targets[i].actions[j].reaction  = ashita.bits.unpack_be( packet_data, bit + 36, 5 );
			act.targets[i].actions[j].animation = ashita.bits.unpack_be( packet_data, bit + 41, 11 );
			act.targets[i].actions[j].effect    = ashita.bits.unpack_be( packet_data, bit + 53, 2 );
			act.targets[i].actions[j].stagger   = ashita.bits.unpack_be( packet_data, bit + 55, 7 );
			act.targets[i].actions[j].param     = ashita.bits.unpack_be( packet_data, bit + 63, 17 );
			act.targets[i].actions[j].message   = ashita.bits.unpack_be( packet_data, bit + 80, 10 );
			act.targets[i].actions[j].unknown   = ashita.bits.unpack_be( packet_data, bit + 90, 31 );
			if (act.category == 6) and (act.actor_id  == my_player_id) and (my_player_id == act.targets[i].id) then
				for k,v in pairs(roll_ja_enums) do
					if (act.param == v) then
						r_name = k;
						r_value = act.targets[i].actions[j].param;
						if (r_name == nil) then
							return false
						else
							return string.lower(r_name), r_value;
						end
					end
				end
				return false;
			end
			if (ashita.bits.unpack_be( packet_data, bit + 121, 1 ) == 1) then -- Does this action have additional effects.. which include skillchains
				act.targets[i].actions[j].has_add_effect        = true;
				act.targets[i].actions[j].add_effect_animation  = ashita.bits.unpack_be( packet_data, bit + 122, 10 );
				act.targets[i].actions[j].add_effect_effect     = 0; -- Unknown currently..
				act.targets[i].actions[j].add_effect_param      = ashita.bits.unpack_be( packet_data, bit + 132, 17 ); --skillchain dmg
				act.targets[i].actions[j].add_effect_message    = ashita.bits.unpack_be( packet_data, bit + 149, 10 ); --120-132=skillchains, 133 = cosmic elucidation
				bit = bit + 37;
			else
				act.targets[i].actions[j].has_add_effect        = false;
				act.targets[i].actions[j].add_effect_animation  = 0;
				act.targets[i].actions[j].add_effect_effect     = 0;
				act.targets[i].actions[j].add_effect_param      = 0;
				act.targets[i].actions[j].add_effect_message    = 0;
			end
			if (ashita.bits.unpack_be( packet_data, bit + 122, 1 ) == 1) then-- Does this action have spike effects..
				act.targets[i].actions[j].has_spike_effect          = true;
				act.targets[i].actions[j].spike_effect_animation    = ashita.bits.unpack_be( packet_data, bit + 123, 10 );
				act.targets[i].actions[j].spike_effect_effect       = 0; -- Unknown currently..
				act.targets[i].actions[j].spike_effect_param        = ashita.bits.unpack_be( packet_data, bit + 133, 14 );
				act.targets[i].actions[j].spike_effect_message      = ashita.bits.unpack_be( packet_data, bit + 147, 10 );
				bit = bit + 34;
			else
				act.targets[i].actions[j].has_spike_effect          = false;
				act.targets[i].actions[j].spike_effect_animation    = 0;
				act.targets[i].actions[j].spike_effect_effect       = 0;
				act.targets[i].actions[j].spike_effect_param        = 0;
				act.targets[i].actions[j].spike_effect_message      = 0;
			end
			bit = bit + 87;
		end
		bit = bit + 36;
	end
	
	return act
end