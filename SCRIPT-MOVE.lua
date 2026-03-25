WorldDrop = "X"
doorDrop = "X"

WorldTake = "X"
doorTake = "X"

patokanPack = 20
Items = {
1258,1260,1262,1264,1266,1268,1270,4308,4310,4312,4314,4316,4318,1241,8500,1256,8558,5038,4296
}
---DONT TOUCH
bot = getBot()

function warp(world, id)
    while bot:getWorld().name ~= world:upper() do
        bot:warp(world:upper())
        sleep(10000)
    end
    if id ~= "" then
        bot:warp(world:upper().."|"..id:upper())
        sleep(1000)
    end
end

function reconnect(world, id, x, y)
    if bot.status ~= BotStatus.online or bot:getPing() == 0 then
        while bot.status ~= BotStatus.online or bot:getPing() == 0 do
            sleep(1000)
            bot.auto_reconnect = true
            if bot.status == BotStatus.account_banned then
                bot.auto_reconnect = false
                bot:stopScript()
            end
        end
        sleep(5000)
    end
    if bot.status == BotStatus.online then
        if world and not bot:isInWorld() then
            warp(world, id)
            if x and y then
                while (bot.x ~= x or bot.y ~= y) do
                    bot:findPath(x, y)
                    sleep(100)
                end
            end
        end
    end
end

function getItemCount(id)
    return bot:getInventory():getItemCount(id)
end

function round(n)
    return n % 1 > 0.5 and math.ceil(n) or math.floor(n)
end

function tileDrop(x,y,num)
    local count = 0
    local stack = 0
    for _,obj in pairs(bot:getWorld():getObjects()) do
        if round(obj.x / 32) == x and math.floor(obj.y / 32) == y then
            count = count + obj.count
            stack = stack + 1
        end
    end
    if stack < 20 and count <= (4000 - num) then
        return true
    end
    return false
end

function take(world,door,id)
    for _,obj in pairs(bot:getWorld():getObjects()) do
        if obj.id == id then
            bot:findPath(round(obj.x/32),(obj.y/32))
            sleep(1000)
            bot:collect(2)
            sleep(1000)
            reconnect(world,door,obj.x/32,(obj.y/32))
            if getItemCount(id) > 0 then
                break
            end
        end
    end
end

function getObjectCount(itemID)
    return (getBot():getWorld().growscan:getObjects()[itemID]) or 0
end

function takeItem(world,door, id)
    warp(world, door)
    sleep(500)
    for _, item in pairs(Items) do
        while true do
            local invCount = getItemCount(item)
            local objCount = getObjectCount(item)
            if invCount >= 200 then
                print("Sudah 200+ "..getInfo(item).name.." di backpack, berhenti ambil.")
                break
            end
            if objCount == 0 then
                print("Tidak ada lagi "..getInfo(item).name.." di world, lanjut ke item berikutnya.")
                break
            end
            take(world,door,item)
            sleep(100)
            reconnect(world, door)
        end
    end
end

function takeItems(world,id)
    warp(world, id)
    sleep(100)
    for _, item in pairs(Item) do
        while getItemCount(item) == 0 do
            if getObjectCount(item) == 0 then
                break
            end
            take(item)
            sleep(100)
        end
    end
end

function Drops()
    if bot:getWorld().name == WorldDrop:upper() then
        for _,pack in pairs(Items) do
            for _,tile in pairs(bot:getWorld():getTiles()) do
                if tile.fg == patokanPack or tile.bg == patokanPack then
                    if tileDrop(tile.x,tile.y,bot:getInventory():findItem(pack)) then
                        bot:findPath(tile.x - 1,tile.y)
                        bot:setDirection(false)
                        sleep(1000)
                        reconnect(WorldDrop, doorDrop,tile.x - 1,tile.y)
                        if bot:getInventory():findItem(pack) > 0 and tileDrop(tile.x,tile.y,bot:getInventory():findItem(pack)) then
                            bot:sendPacket(2,"action|drop\n|itemID|"..pack)
                            sleep(500)
                            bot:sendPacket(2,"action|dialog_return\ndialog_name|drop_item\nitemID|"..pack.."|\ncount|"..bot:getInventory():findItem(pack))
                            sleep(500)
                            reconnect(WorldDrop, doorDrop,tile.x - 1,tile.y)
                        end
                    end
                end
                if bot:getInventory():findItem(pack) == 0 then
                    break
                end
            end
        end
    end
end

while true do
    takeItem(WorldTake, doorTake)
    sleep(100)
    warp(WorldDrop, doorDrop)
    sleep(1000)
    Drops()
end
