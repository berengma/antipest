
local S = technic.getter

local storage = minetest.get_mod_storage()
local score = {}

local adminname               = "Gundul" -- Admins do not have highscores !
local cleanup_max_charge      = 30000 -- Maximum charge of the cleaner
local enable_drops            = true  -- enable drops or not
local cleanup_charge_per_node = 5     -- energy used to kill one sunflower
local car = 20                        -- cleanup_action_radius
local chatmessage             = true
local runonjungle             = false  -- do not set to true unless you worked over the prizes table (see comment below)

technic.register_power_tool("antipest:cleanup", cleanup_max_charge)

-- *** important notice concerning prizes
-- if you want to make it work turn runonjungle to "true" and edit the below list
-- which must suit to the mods you have onyour server
--
-- the list is :    number of killes sunflowers, name of node you get as a gift, how many in number of that node, string which is written in chat
--
-- for example line one here says: killing 10000 sunflowers will add 100 moretrees:raw_coconut to your inventory, using "raw_coconut" as chat output
--
-- ***


local prizes = {
		  {10000, "moretrees:raw_coconut", 100, "raw coconut"},
		  {10001, "indofood:gula_merah", 50, "palm sugar"},
		  {20000, "default:copperblock", 100, "copper blocks"},
		  {30000, "clams:collectedalgae", 512, "collected algae"},
		  {40000, "default:diamondblock", 100, "diamond blocks"},
		  {50000, "clams:crushedwhite", 1024, "crushed shell"},
		  {60000, "technic:chromium_block", 100, "chromium blocks"},
		  {70000, "lavaex:lavaex", 512, "lava extingisher"},
		  {80000, "moretrees:palm_fruit_trunk", 10, "coconut fruit trunks"},
		  {90000, "moretrees:date_palm_ffruit_trunk", 10, "date palm fruit trunks"},
		  {100000, "aviator:aviator", 128, "flight devices"}
		  
}



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


local function check_prizes(user,number)
      local name = user:get_player_name()
      local inv = user:get_inventory()
      for i in ipairs(prizes) do
         local goal = prizes[i][1]
	 local nodename = prizes[i][2]
	 local howmuch = prizes[i][3]
	 local sayit = prizes[i][4]
	 
	    if score[name] + number == goal then
		  minetest.chat_send_player(name, core.colorize("#FF6700", "Congratulation: You killed your "..goal.."s evil sunflower !! Keep up the good work. "..howmuch.." "..sayit.." have been added to your inv"))
		  inv:add_item("main", {name=nodename, count=howmuch})
	    end
      end
end
      
      
      

local function cleanup_dig(pos, current_charge, user)
	local name = user:get_player_name()
	local minp = vector.subtract(pos, car)
        local maxp = vector.add(pos, car)
	local counter = 0
	local countall = 0

	local poslist = minetest.find_nodes_in_area(minp, maxp, {"flowers:sunflower","group:nettle_weed"})

		for _,cpos in pairs(poslist) do

					
			if not minetest.is_protected(cpos, name) then
			   
			   if current_charge > cleanup_charge_per_node then

				current_charge = current_charge - cleanup_charge_per_node
				if minetest.get_node(cpos).name == "flowers:sunflower" then
					counter = counter +1
				end
				countall = countall + 1
				minetest.remove_node(cpos)
				
				if score[name] and runonjungle then check_prizes(user,counter) end
				
			   else
			
			      break

			   end

			end
		
			
		end	

	
	if counter > 0 then

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
	end
	
		      
	if enable_drops and countall > 0 then
		local inv = user:get_inventory()
		local blocks = math.floor(countall/81)
		local lumps = math.floor((countall-blocks*81)/9) 
       
		inv:add_item("main", {name="default:coal_lump", count=lumps})
		inv:add_item("main", {name="default:coalblock", count=blocks})

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
	      if score[name] then minetest.chat_send_player(name, core.colorize("#FF6700", ">>> Your score is: "..score[name])) end
	      minetest.show_formspec(name, "antipest:the_killers", fname)
	    end

	end,
})

-- Go and get them :D

openlist()



