local RSGCore = exports['rsg-core']:GetCoreObject()

-- Initialize Database
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    -- Create or update fines table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_fines (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            firstname VARCHAR(50) NOT NULL,
            lastname VARCHAR(50) NOT NULL,
            reason VARCHAR(255) NOT NULL,
            amount INT NOT NULL,
            status VARCHAR(20) DEFAULT 'unpaid',
            officername VARCHAR(100) NOT NULL,
            officerjob VARCHAR(50) NOT NULL,
            date DATETIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid),
            INDEX idx_date (date)
        )
    ]])
    
    -- Create or update weapons table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_weapons (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_name VARCHAR(100) NOT NULL,
            weapon_name VARCHAR(50) NOT NULL,
            serial_number VARCHAR(50) NOT NULL UNIQUE,
            registered_by VARCHAR(100) NOT NULL,
            date DATETIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_name),
            INDEX idx_serial (serial_number)
        )
    ]])
end)

-- Search Citizens
RegisterNetEvent('pure-mdt:server:searchCitizens', function(searchTerm)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    -- Search in players table using JSON_EXTRACT for charinfo
    MySQL.query([[
        SELECT 
            citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) as firstname,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) as lastname
        FROM players 
        WHERE 
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) LIKE ? 
            OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) LIKE ? 
        LIMIT 10
    ]], 
    {'%'..searchTerm..'%', '%'..searchTerm..'%'},
    function(results)
        if Config.Debug then
            print('Search results:', json.encode(results))
        end
        TriggerClientEvent('pure-mdt:client:showCitizenResults', src, results)
    end)
end)

-- Search Citizens for Weapon Registration
RegisterNetEvent('pure-mdt:server:searchCitizensForWeapon', function(searchTerm, weaponData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    MySQL.query([[
        SELECT 
            citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) as firstname,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) as lastname
        FROM players 
        WHERE 
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) LIKE ? 
            OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) LIKE ? 
        LIMIT 10
    ]], 
    {'%'..searchTerm..'%', '%'..searchTerm..'%'},
    function(results)
        TriggerClientEvent('pure-mdt:client:showCitizenResultsForWeapon', src, results, weaponData)
    end)
end)

-- Create Fine
RegisterNetEvent('pure-mdt:server:createFine', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(data.targetId)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    if data.amount < Config.MinFineAmount or data.amount > Config.MaxFineAmount then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.invalid_amount, 'error')
        return
    end
    
    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local currentDate = os.date('%Y-%m-%d %H:%M:%S')
    
    MySQL.insert('INSERT INTO '..Config.Tables.fines..' (citizenid, firstname, lastname, reason, amount, status, officername, officerjob, date, confiscated_weapon, prison_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.citizenid,
            data.firstname,
            data.lastname,
            data.reason,
            data.amount,
            'unpaid',
            officerName,
            Player.PlayerData.job.name,
            currentDate,
            data.confiscated_weapon or nil,
            data.prison_time or nil
        },
        function(id)
            if id then
                -- Modified Discord message to include new fields
                local message = string.format("**Officer:** %s\n**Citizen:** %s %s\n**Amount:** $%s\n**Reason:** %s\n**Confiscated Weapon:** %s\n**Prison Time:** %s",
                    officerName,
                    data.firstname,
                    data.lastname,
                    data.amount,
                    data.reason,
                    data.confiscated_weapon or "None",
                    data.prison_time or "None"
                )
                SendToDiscord(Config.Webhooks.fines.new, "New Fine Created", message, Config.WebhookColors.new)
                
                TriggerClientEvent('RSGCore:Notify', src, Config.Locales.fine_created, 'success')
                if Target then
                    TriggerClientEvent('RSGCore:Notify', Target.PlayerData.source, Config.Locales.fine_received, 'primary')
                end
            end
        end
    )
end)

-- Register Weapon
RegisterNetEvent('pure-mdt:server:registerWeapon', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    local registeredBy = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local currentDate = os.date('%Y-%m-%d %H:%M:%S')
    
    MySQL.scalar('SELECT 1 FROM '..Config.Tables.weapons..' WHERE serial_number = ?', {data.serial},
        function(exists)
            if exists then
                TriggerClientEvent('RSGCore:Notify', src, Config.Locales.weapon_exists, 'error')
                return
            end
            
            MySQL.insert('INSERT INTO '..Config.Tables.weapons..' (owner_name, weapon_name, serial_number, registered_by, date, citizenid) VALUES (?, ?, ?, ?, ?, ?)',
                {
                    data.owner,
                    data.weapon,
                    data.serial,
                    registeredBy,
                    currentDate,
                    data.citizenid -- Added citizenid
                },
                function(id)
                    if id then
                        -- Send to Discord with citizenid
                        local message = string.format("**Registered By:** %s\n**Owner:** %s\n**CID:** %s\n**Weapon:** %s\n**Serial:** %s",
                            registeredBy,
                            data.owner,
                            data.citizenid,
                            data.weapon,
                            data.serial
                        )
                        SendToDiscord(Config.Webhooks.weapons.new, "New Weapon Registered", message, Config.WebhookColors.new)
                        
                        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.weapon_registered, 'success')
                    end
                end
            )
        end
    )
end)

-- Search Functions
RegisterNetEvent('pure-mdt:server:searchFines', function(searchTerm)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    MySQL.query('SELECT * FROM '..Config.Tables.fines..' WHERE firstname LIKE ? OR lastname LIKE ? ORDER BY date DESC',
        {'%'..searchTerm..'%', '%'..searchTerm..'%'},
        function(results)
            TriggerClientEvent('pure-mdt:client:showSearchResults', src, results or {}, 'fines')
        end
    )
end)

-- Search Weapon by Serial
RegisterNetEvent('pure-mdt:server:searchWeaponBySerial', function(serial)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    MySQL.query('SELECT *, citizenid FROM '..Config.Tables.weapons..' WHERE serial_number LIKE ? ORDER BY date DESC',
        {'%'..serial..'%'},
        function(results)
            TriggerClientEvent('pure-mdt:client:showSearchResults', src, results or {}, 'weapons')
        end
    )
end)


-- Search Weapon by Owner
RegisterNetEvent('pure-mdt:server:searchWeaponByOwner', function(owner)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    MySQL.query('SELECT *, citizenid FROM '..Config.Tables.weapons..' WHERE owner_name LIKE ? ORDER BY date DESC',
        {'%'..owner..'%'},
        function(results)
            TriggerClientEvent('pure-mdt:client:showSearchResults', src, results or {}, 'weapons')
        end
    )
end)

function SendToDiscord(webhook, title, message, color)
    if not Config.Webhooks.enable then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "RSG-MDT • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Pure - Шерифско MDT",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Get Personal Fines
RegisterNetEvent('pure-mdt:server:getPersonalFines', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Config.Debug then
        print('Getting personal fines for:', src)
    end
    
    if not Player then return end
    
    MySQL.query('SELECT * FROM '..Config.Tables.fines..' WHERE citizenid = ? AND status = ? ORDER BY date DESC',
        {Player.PlayerData.citizenid, 'unpaid'},
        function(results)
            if Config.Debug then
                print('Found fines:', json.encode(results or {}))
            end
            TriggerClientEvent('pure-mdt:client:showPersonalFines', src, results or {})
        end
    )
end)

-- Pay Fine
RegisterNetEvent('pure-mdt:server:payFine', function(fineId, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    MySQL.single('SELECT * FROM '..Config.Tables.fines..' WHERE id = ? AND citizenid = ? AND status = ?',
        {fineId, Player.PlayerData.citizenid, 'unpaid'},
        function(fine)
            if fine then
                if Player.Functions.RemoveMoney('cash', fine.amount, 'fine-payment') then
                    MySQL.update('UPDATE '..Config.Tables.fines..' SET status = ? WHERE id = ?',
                        {'paid', fineId},
                        function(affectedRows)
                            if affectedRows > 0 then
                                -- Send to Discord
                                local message = string.format("**Citizen:** %s %s\n**Amount:** $%s\n**Original Reason:** %s",
                                    fine.firstname,
                                    fine.lastname,
                                    fine.amount,
                                    fine.reason
                                )
                                SendToDiscord(Config.Webhooks.fines.paid, "Fine Paid", message, Config.WebhookColors.paid)
                                
                                TriggerClientEvent('RSGCore:Notify', src, Config.Locales.fine_paid_success, 'success')
                                -- Refresh fines list
                                MySQL.query('SELECT * FROM '..Config.Tables.fines..' WHERE citizenid = ? AND status = ? ORDER BY date DESC',
                                    {Player.PlayerData.citizenid, 'unpaid'},
                                    function(results)
                                        TriggerClientEvent('pure-mdt:client:showPersonalFines', src, results or {})
                                    end
                                )
                            end
                        end
                    )
                else
                    TriggerClientEvent('RSGCore:Notify', src, Config.Locales.insufficient_funds, 'error')
                end
            end
        end
    )
end)

-- Delete Functions
RegisterNetEvent('pure-mdt:server:deleteFine', function(fineId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    -- Get fine details before deletion
    MySQL.single('SELECT * FROM '..Config.Tables.fines..' WHERE id = ?', {fineId},
        function(fine)
            if fine then
                MySQL.update('DELETE FROM '..Config.Tables.fines..' WHERE id = ?',
                    {fineId},
                    function(affectedRows)
                        if affectedRows > 0 then
                            -- Send to Discord
                            local message = string.format("**Deleted By:** %s %s\n**Original Fine Details:**\nCitizen: %s %s\nAmount: $%s\nReason: %s",
                                Player.PlayerData.charinfo.firstname,
                                Player.PlayerData.charinfo.lastname,
                                fine.firstname,
                                fine.lastname,
                                fine.amount,
                                fine.reason
                            )
                            SendToDiscord(Config.Webhooks.fines.deleted, "Fine Deleted", message, Config.WebhookColors.deleted)
                            
                            TriggerClientEvent('RSGCore:Notify', src, Config.Locales.fine_deleted, 'success')
                        end
                    end
                )
            end
        end
    )
end)


RegisterNetEvent('pure-mdt:server:deleteWeaponRegistration', function(serialNumber)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('RSGCore:Notify', src, Config.Locales.no_permission, 'error')
        return
    end
    
    -- Get weapon details before deletion
    MySQL.single('SELECT * FROM '..Config.Tables.weapons..' WHERE serial_number = ?', {serialNumber},
        function(weapon)
            if weapon then
                MySQL.update('DELETE FROM '..Config.Tables.weapons..' WHERE serial_number = ?',
                    {serialNumber},
                    function(affectedRows)
                        if affectedRows > 0 then
                            -- Send to Discord
                            local message = string.format("**Deleted By:** %s %s\n**Original Registration Details:**\nOwner: %s\nWeapon: %s\nSerial: %s",
                                Player.PlayerData.charinfo.firstname,
                                Player.PlayerData.charinfo.lastname,
                                weapon.owner_name,
                                weapon.weapon_name,
                                weapon.serial_number
                            )
                            SendToDiscord(Config.Webhooks.weapons.deleted, "Weapon Registration Deleted", message, Config.WebhookColors.deleted)
                            
                            TriggerClientEvent('RSGCore:Notify', src, Config.Locales.weapon_registration_deleted, 'success')
                        end
                    end
                )
            end
        end
    )
end)

-- Admin Commands
RSGCore.Commands.Add('mdtreset', 'Reset MDT Database (Admin Only)', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if Player.PlayerData.job.grade >= Config.AdminGrade then
        MySQL.query('TRUNCATE TABLE '..Config.Tables.fines)
        MySQL.query('TRUNCATE TABLE '..Config.Tables.weapons)
        TriggerClientEvent('RSGCore:Notify', source, 'MDT Database has been reset', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', source, Config.Locales.no_permission, 'error')
    end
end, 'admin')