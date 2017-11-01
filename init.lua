
local S = technic.getter

local storage = minetest.get_mod_storage()
local score = {}

local adminname               = "Gundul" -- Admins do not have highscores !
local cleanup_max_charge      = 30000 -- Maximum charge of the cleaner
local enable_drops            = true  -- enable drops or not
local cleanup_charge_per_node = 5     -- energy used to kill one sunflower
local car = 20                        -- cleanup_action_radius
local chatmessage             = true

technic.register_power_tool("antipest:cleanup", cleanup_max_charge)


-- load scoreboard
local function openlist()

	local load = storage:to_table()
	score = load.fields
	
	for count in pairs(score) do
	score[count] = tonumber(score[count])
	end
    
end


-- save scoreboard
local function savelist()

	storage:from_table({fields=score})
	
end -- poi.save()


function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


local function sortscore()
    local fname = "size[5,6]"
    local count = 1

      for k,v in spairs(score, function(t,a,b) return t[b] < t[a] end) do
	  --minetest.chat_send_all(count.." >>> "..k.." , "..v)
	  fname = fname.."label[1,"..(count*0.3)..";"..count.." >>> "..k.." , "..v.."]"
	  count = count + 1
	  if count > 10 then break end
      end
  
    fname = fname.."button_exit[1.5,5;2,1;quit;Exit]"
    return fname
end


local function cleanup_dig(pos, current_charge, user)
	local name = user:get_player_name()
	local minp = vector.subtract(pos, car)
        local maxp = vector.add(pos, car)
	local counter = 0

	local poslist = minetest.find_nodes_in_area(minp, maxp, {"flowers:sunflower"})

		for _,cpos in pairs(poslist) do

					
			if not minetest.is_protected(cpos, name) then
			   
			   if current_charge > cleanup_charge_per_node then

				current_charge = current_charge - cleanup_charge_per_node
				minetest.remove_node(cpos)
				counter = counter +1
			   else
			
			      break

			   end

			end
		
			
		end	

	
	if counter > 1 then

		if chatmessage then

		minetest.chat_send_player(name, "You just killed "..counter.." evil sunflowers")
		        
		end
		
		if name ~= adminname then
		      if score[name] then
				score[name] = score[name] + counter
			    else
				score[name] = counter
		      end
		end
		      
		if enable_drops then
			local inv = user:get_inventory()
			local blocks = math.floor(counter/81)
			local lumps = math.floor((counter-blocks*81)/9) 
        
        		inv:add_item("main", {name="default:coal_lump", count=lumps})
			inv:add_item("main", {name="default:coalblock", count=blocks})

		end

	end

	savelist()
	return current_charge
			
				
end




minetest.register_tool("antipest:cleanup", {
	description = S("Kill all the evil sunflowers"),
	inventory_image = "antipest_cleanup.png",
	stack_max = 1,
	wear_represents = "technic_RE_charge",
	on_refill = technic.refill_RE_charge,
	on_use = function(itemstack, user, pointed_thing)
	   local name = user:get_player_name()
	   
	      if pointed_thing.under ~= nil then
	        
		local meta = minetest.deserialize(itemstack:get_metadata())
		if not meta or not meta.charge or
				meta.charge < cleanup_charge_per_node then
			return
		end

		

		-- Send current charge to digging function so that the
		-- cleanup will stop after digging a number of nodes
		meta.charge = cleanup_dig(pointed_thing.under, meta.charge, user)
		if not technic.creative_mode then
			technic.set_RE_wear(itemstack, meta.charge, cleanup_max_charge)
			itemstack:set_metadata(minetest.serialize(meta))
		end
	    end
	   
   	   return itemstack
	   
	        
	end,

	on_place = function(itemstack, placer, pointed_thing)

		local name = placer:get_player_name()

		chatmessage = not chatmessage
		if chatmessage then 

			minetest.chat_send_player(name,">>> Antipest report is ON")

		else

			minetest.chat_send_player(name,">>> Antipest report is OFF")

		end

	end,


})

minetest.register_craft({
	output = "antipest:cleanup",
	recipe = {
		{"technic:stainless_steel_ingot", "technic:stainless_steel_ingot", "technic:stainless_steel_ingot"},
		{"technic:stainless_steel_ingot", "technic:battery",""},
		{"technic:stainless_steel_ingot", "technic:red_energy_crystal", "technic:stainless_steel_ingot"},
	}
})

minetest.register_chatcommand("score", {
	params = "",
	description = "Shows the best sunflower killer",
	privs = {interact = true},
	func = function(name)

	    local fname = sortscore()
	    if fname then
	      --minetest.chat_send_player(name, ">>> Highscore is :"..score[highscore].." by "..highscore)
	      minetest.show_formspec(name, "antipest:the_killers", fname)
	    end

	end,
})

-- Go and get them :D

openlist()



