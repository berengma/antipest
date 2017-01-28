
local S = technic.getter


local cleanup_max_charge      = 30000 -- Maximum charge of the cleaner
local enable_drops            = true  -- enable drops or not
local cleanup_charge_per_node = 5     -- energy used to kill one sunflower
local car = 20                        -- cleanup_action_radius
local chatmessage             = true





technic.register_power_tool("antipest:cleanup", cleanup_max_charge)



local function cleanup_dig(pos, current_charge, user)
	local name = user:get_player_name()
	local minp = vector.subtract(pos, car)
        local maxp = vector.add(pos, car)
	local counter = 0

	local poslist = minetest.find_nodes_in_area(minp, maxp, {"flowers:sunflower"})

	-- this debugs positions
	-- minetest.chat_send_player(name, " you hit : "..pos.x.." , "..pos.y.." , "..pos.z)
	-- minetest.chat_send_player(name, " minp    : "..minp.x.." , "..minp.y.." , "..minp.z)
	-- minetest.chat_send_player(name, " maxp    : "..maxp.x.." , "..maxp.y.." , "..maxp.z)

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

		if enable_drops then
			local inv = user:get_inventory()
			local blocks = math.floor(counter/81)
			local lumps = math.floor((counter-blocks*81)/9) 
        
        		inv:add_item("main", {name="default:coal_lump", count=lumps})
			inv:add_item("main", {name="default:coalblock", count=blocks})

		end

	end

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

