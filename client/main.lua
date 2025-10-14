local RSGCore = exports['rsg-core']:GetCoreObject()

local function FormatDate(dateString)
    if not dateString then return "N/A" end
    
    local year, month, day, hour, minute = string.match(dateString, "(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    if not year then return dateString end
    
    return string.format("%s/%s/%s %s:%s", day, month, year, hour, minute)
end

-- Function to get currently equipped weapon
function GetEquippedWeapon()
    local playerPed = PlayerPedId()
    local success, weaponHash = GetCurrentPedWeapon(playerPed)
    local Player = RSGCore.Functions.GetPlayerData()
    local inventory = Player.items
    
    if Config.Debug then
        print('Current weapon hash:', weaponHash)
    end

    -- Find the equipped weapon in inventory that matches current weapon hash
    for _, item in pairs(inventory) do
        if item.type == 'weapon' and GetHashKey(item.name) == weaponHash then
            if Config.Debug then
                print('Found matching weapon:')
                print('Name:', item.name)
                print('Label:', item.label)
                print('Serie:', item.info and item.info.serie or 'No serie')
            end
            
            if item.info and item.info.serie then
                return {
                    name = item.name,
                    label = item.label,
                    serial = item.info.serie
                }
            end
        end
    end
    
    return nil
end

-- Main MDT Command
RegisterCommand(Config.Command, function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if Config.AllowedJobs[PlayerData.job.name] then
        OpenMainMenu()
    else
        RSGCore.Functions.Notify(Config.Locales.no_permission, 'error')
    end
end)

-- Check Fines Command
RegisterCommand(Config.CheckFine, function()
    TriggerServerEvent('pure-mdt:server:getPersonalFines')
end)

-- Main Menu Function
function OpenMainMenu()
    local mainMenu = {
        {
            header = Config.Locales.mdt_title,
            isMenuHeader = true,
        },
        {
            header = Config.Locales.create_fine,
            txt = Config.Locales.fine_desc,
            params = {
                event = 'pure-mdt:client:createFine'
            }
        },
        {
            header = Config.Locales.search_fines,
            txt = Config.Locales.search_name,
            params = {
                event = 'pure-mdt:client:searchFines'
            }
        },
        {
            header = Config.Locales.register_weapon,
            txt = Config.Locales.weapon_registration,
            params = {
                event = 'pure-mdt:client:registerWeapon'
            }
        },
        {
            header = Config.Locales.search_weapons,
            txt = Config.Locales.search_weapons,
            params = {
                event = 'pure-mdt:client:searchWeapons'
            }
        },
        {
            header = Config.Locales.close_menu,
            txt = '',
            params = {
                event = 'rsg-menu:closeMenu'
            }
        }
    }

    exports['rsg-menu']:openMenu(mainMenu)
end

-- Create Fine Event
RegisterNetEvent('pure-mdt:client:createFine', function()
    local dialog = exports['rsg-input']:ShowInput({
        header = Config.Locales.search_citizen,
        submitText = Config.Locales.search,
        inputs = {
            {
                text = Config.Locales.search_name,
                name = "searchterm",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:searchCitizens', dialog.searchterm)
    end
end)

-- Show Citizen Results for Fine Creation
RegisterNetEvent('pure-mdt:client:showCitizenResults', function(results)
    local citizenMenu = {
        {
            header = Config.Locales.select_citizen,
            isMenuHeader = true
        }
    }

    if results and #results > 0 then
        for _, v in pairs(results) do
            table.insert(citizenMenu, {
                header = string.format('%s %s', v.firstname, v.lastname),
                txt = string.format('CitizenID: %s', v.citizenid),
                params = {
                    event = 'pure-mdt:client:createFineForCitizen',
                    args = v
                }
            })
        end
    else
        table.insert(citizenMenu, {
            header = Config.Locales.no_results,
            txt = '',
            isMenuHeader = true
        })
    end

    table.insert(citizenMenu, {
        header = Config.Locales.back,
        txt = '',
        params = {
            event = 'pure-mdt:client:openMainMenu'
        }
    })

    exports['rsg-menu']:openMenu(citizenMenu)
end)

-- Create Fine for Selected Citizen
RegisterNetEvent('pure-mdt:client:createFineForCitizen', function(citizenData)
    local dialog = exports['rsg-input']:ShowInput({
        header = string.format(Config.Locales.create_fine, citizenData.firstname, citizenData.lastname),
        submitText = Config.Locales.submit,
        inputs = {
            {
                text = Config.Locales.reason,
                name = "reason",
                type = "text",
                isRequired = true
            },
            {
                text = Config.Locales.amount,
                name = "amount",
                type = "number",
                isRequired = true
            },
            {
                text = Config.Locales.confiscated_weapon,
                name = "confiscated_weapon",
                type = "text",
                isRequired = false
            },
            {
                text = Config.Locales.prison_time,
                name = "prison_time",
                type = "text",
                isRequired = false
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:createFine', {
            targetId = citizenData.id,
            firstname = citizenData.firstname,
            lastname = citizenData.lastname,
            citizenid = citizenData.citizenid,
            reason = dialog.reason,
            amount = tonumber(dialog.amount),
            confiscated_weapon = dialog.confiscated_weapon,
            prison_time = dialog.prison_time
        })
    end
end)
-- Search Fines Event
RegisterNetEvent('pure-mdt:client:searchFines', function()
    local dialog = exports['rsg-input']:ShowInput({
        header = Config.Locales.search_fines,
        submitText = Config.Locales.submit,
        inputs = {
            {
                text = Config.Locales.search_name,
                name = "searchterm",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:searchFines', dialog.searchterm)
    end
end)

-- Register Weapon Event
RegisterNetEvent('pure-mdt:client:registerWeapon', function()
    -- First check if has weapon in hands
    local weaponData = GetEquippedWeapon()
    
    if not weaponData then
        RSGCore.Functions.Notify(Config.Locales.no_weapon_equipped, 'error')
        return
    end

    if not weaponData.serial then
        RSGCore.Functions.Notify(Config.Locales.no_serial_found, 'error')
        return
    end

    -- Show search dialog for citizen
    local dialog = exports['rsg-input']:ShowInput({
        header = Config.Locales.search_citizen,
        submitText = Config.Locales.search,
        inputs = {
            {
                text = Config.Locales.search_name,
                name = "searchterm",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:searchCitizensForWeapon', dialog.searchterm, weaponData)
    end
end)

-- Show Citizen Results for Weapon Registration
RegisterNetEvent('pure-mdt:client:showCitizenResultsForWeapon', function(results, weaponData)
    local citizenMenu = {
        {
            header = Config.Locales.select_weapon_owner,
            isMenuHeader = true
        }
    }

    if results and #results > 0 then
        for _, v in pairs(results) do
            table.insert(citizenMenu, {
                header = string.format('%s %s', v.firstname, v.lastname),
                txt = string.format('CitizenID: %s', v.citizenid),
                params = {
                    event = 'pure-mdt:client:confirmWeaponRegistration',
                    args = {
                        citizen = v,
                        weapon = weaponData
                    }
                }
            })
        end
    else
        table.insert(citizenMenu, {
            header = Config.Locales.no_results,
            txt = '',
            isMenuHeader = true
        })
    end

    exports['rsg-menu']:openMenu(citizenMenu)
end)

-- Confirm Weapon Registration
RegisterNetEvent('pure-mdt:client:confirmWeaponRegistration', function(data)
    local confirmMenu = {
        {
            header = Config.Locales.confirm_registration,
            isMenuHeader = true
        },
        {
            header = string.format('%s: %s %s', Config.Locales.owner, data.citizen.firstname, data.citizen.lastname),
            txt = string.format('%s: %s\n%s: %s', 
                Config.Locales.weapon_name, data.weapon.label,
                Config.Locales.serial_number, data.weapon.serial
            ),
            isMenuHeader = true
        },
        {
            header = Config.Locales.confirm,
            txt = Config.Locales.confirm_desc,
            params = {
                event = 'pure-mdt:client:finalizeWeaponRegistration',
                args = data
            }
        },
        {
            header = Config.Locales.cancel,
            txt = '',
            params = {
                event = 'pure-mdt:client:openMainMenu'
            }
        }
    }

    exports['rsg-menu']:openMenu(confirmMenu)
end)

-- Finalize Weapon Registration
RegisterNetEvent('pure-mdt:client:finalizeWeaponRegistration', function(data)
    TriggerServerEvent('pure-mdt:server:registerWeapon', {
        owner = string.format('%s %s', data.citizen.firstname, data.citizen.lastname),
        weapon = data.weapon.label,
        serial = data.weapon.serial,
        citizenid = data.citizen.citizenid
    })
end)

-- Search Weapons Menu
RegisterNetEvent('pure-mdt:client:searchWeapons', function()
    local weaponMenu = {
        {
            header = Config.Locales.search_weapons,
            isMenuHeader = true
        },
        {
            header = Config.Locales.search_current_weapon,
            txt = Config.Locales.search_current_desc,
            params = {
                event = 'pure-mdt:client:searchCurrentWeapon'
            }
        },
        {
            header = Config.Locales.search_by_serial,
            txt = Config.Locales.serial_number,
            params = {
                event = 'pure-mdt:client:searchWeaponBySerial'
            }
        },
        {
            header = Config.Locales.search_by_owner,
            txt = Config.Locales.weapon_owner,
            params = {
                event = 'pure-mdt:client:searchWeaponByOwner'
            }
        },
        {
            header = Config.Locales.back,
            txt = '',
            params = {
                event = 'pure-mdt:client:openMainMenu'
            }
        }
    }

    exports['rsg-menu']:openMenu(weaponMenu)
end)

-- Search Current Weapon
RegisterNetEvent('pure-mdt:client:searchCurrentWeapon', function()
    local weaponData = GetEquippedWeapon()
    
    if not weaponData then
        RSGCore.Functions.Notify(Config.Locales.no_weapon_equipped, 'error')
        return
    end

    if not weaponData.serial then
        RSGCore.Functions.Notify(Config.Locales.no_serial_found, 'error')
        return
    end

    TriggerServerEvent('pure-mdt:server:searchWeaponBySerial', weaponData.serial)
end)
-- Search Weapon by Serial
RegisterNetEvent('pure-mdt:client:searchWeaponBySerial', function()
    local dialog = exports['rsg-input']:ShowInput({
        header = Config.Locales.search_by_serial,
        submitText = Config.Locales.submit,
        inputs = {
            {
                text = Config.Locales.serial_number,
                name = "serial",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:searchWeaponBySerial', dialog.serial)
    end
end)

-- Search Weapon by Owner
RegisterNetEvent('pure-mdt:client:searchWeaponByOwner', function()
    local dialog = exports['rsg-input']:ShowInput({
        header = Config.Locales.search_by_owner,
        submitText = Config.Locales.submit,
        inputs = {
            {
                text = Config.Locales.weapon_owner,
                name = "owner",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        TriggerServerEvent('pure-mdt:server:searchWeaponByOwner', dialog.owner)
    end
end)

-- Show Search Results (For both fines and weapons)
RegisterNetEvent('pure-mdt:client:showSearchResults', function(results, searchType)
    local resultMenu = {
        {
            header = Config.Locales.search_results,
            isMenuHeader = true
        }
    }

    if results and #results > 0 then
        for _, v in pairs(results) do
            if searchType == 'fines' then
                table.insert(resultMenu, {
                    header = string.format('%s %s - $%s', v.firstname or 'N/A', v.lastname or 'N/A', v.amount),
                    txt = string.format('%s\n%s: %s\n%s: %s\n%s: %s\n%s: %s',
                        v.reason,
                        Config.Locales.date_issued, FormatDate(v.date),
                        Config.Locales.issued_by, v.officername,
                        Config.Locales.status, v.status or 'unpaid',
                        'CID', v.citizenid
                    ),
                    params = {
                        event = 'pure-mdt:client:viewFineDetails',
                        args = v
                    }
                })
            else
                table.insert(resultMenu, {
                    header = v.weapon_name or 'Unknown Weapon',
                    txt = string.format('%s: %s\n%s: %s\n%s: %s\n%s: %s',
                        Config.Locales.weapon_owner, v.owner_name,
                        Config.Locales.serial_number, v.serial_number,
                        Config.Locales.registration_date, FormatDate(v.date),
                        'CID', v.citizenid
                    ),
                    params = {
                        event = 'pure-mdt:client:viewWeaponDetails',
                        args = v
                    }
                })
            end
        end
    else
        table.insert(resultMenu, {
            header = Config.Locales.no_results,
            txt = '',
            isMenuHeader = true
        })
    end

    table.insert(resultMenu, {
        header = Config.Locales.back,
        txt = '',
        params = {
            event = searchType == 'fines' and 'pure-mdt:client:openMainMenu' or 'pure-mdt:client:searchWeapons'
        }
    })

    exports['rsg-menu']:openMenu(resultMenu)
end)

-- Show Personal Fines
RegisterNetEvent('pure-mdt:client:showPersonalFines', function(fines)
    local fineMenu = {
        {
            header = Config.Locales.your_fines,
            isMenuHeader = true
        }
    }

    if fines and #fines > 0 then
        for _, fine in pairs(fines) do
            table.insert(fineMenu, {
                header = string.format('$%s - %s', fine.amount, fine.reason),
                txt = string.format('%s: %s\n%s: %s\n%s: %s\n%s: %s',
                    Config.Locales.issued_by, fine.officername,
                    Config.Locales.date_issued, FormatDate(fine.date),
                    Config.Locales.status, fine.status or 'unpaid',
                    'CID', fine.citizenid
                ),
                params = {
                    event = 'pure-mdt:client:fineOptions',
                    args = fine
                }
            })
        end
    else
        table.insert(fineMenu, {
            header = Config.Locales.no_unpaid_fines,
            txt = '',
            isMenuHeader = true
        })
    end

    table.insert(fineMenu, {
        header = Config.Locales.close,
        txt = '',
        params = {
            event = 'rsg-menu:closeMenu'
        }
    })

    exports['rsg-menu']:openMenu(fineMenu)
end)

-- Fine Options Menu
RegisterNetEvent('pure-mdt:client:fineOptions', function(fine)
    local optionsMenu = {
        {
            header = string.format(Config.Locales.fine_details, fine.amount),
            isMenuHeader = true
        },
        {
            header = Config.Locales.pay_fine,
            txt = string.format(Config.Locales.pay_fine_desc, fine.amount),
            params = {
                event = 'pure-mdt:client:confirmPayFine',
                args = fine
            }
        },
        {
            header = Config.Locales.back,
            txt = '',
            params = {
                event = 'pure-mdt:client:showPersonalFines'
            }
        }
    }

    exports['rsg-menu']:openMenu(optionsMenu)
end)

RegisterNetEvent('pure-mdt:client:confirmPayFine', function(fine)
    local confirmMenu = {
        {
            header = string.format(Config.Locales.confirm_payment, fine.amount),
            isMenuHeader = true
        },
        {
            header = Config.Locales.pay,
            txt = string.format(Config.Locales.pay_fine_desc, fine.amount),
            params = {
                event = 'pure-mdt:client:processFinePayment',
                args = fine
            }
        },
        {
            header = Config.Locales.cancel,
            txt = '',
            params = {
                event = 'pure-mdt:client:fineOptions',
                args = fine
            }
        }
    }

    exports['rsg-menu']:openMenu(confirmMenu)
end)

-- New process payment event
RegisterNetEvent('pure-mdt:client:processFinePayment', function(fine)
    if Config.Debug then
        print('Processing fine payment:', fine.id, 'Amount:', fine.amount)
    end
    TriggerServerEvent('pure-mdt:server:payFine', fine.id, fine.amount)
end)

-- Pay Fine
RegisterNetEvent('pure-mdt:client:payFine', function(fine)
    local dialog = exports['rsg-input']:ShowInput({
        header = string.format(Config.Locales.confirm_payment, fine.amount),
        submitText = Config.Locales.pay,
        inputs = {
            {
                text = Config.Locales.type_confirm,
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog then
        if dialog.confirm == 'confirm' then
            if Config.Debug then
                print('Attempting to pay fine:', fine.id, 'Amount:', fine.amount)
            end
            TriggerServerEvent('pure-mdt:server:payFine', fine.id, fine.amount)
        else
            RSGCore.Functions.Notify(Config.Locales.error_invalid_input, 'error')
        end
    end
end)

-- View Fine Details
RegisterNetEvent('pure-mdt:client:viewFineDetails', function(data)
    local detailMenu = {
        {
            header = string.format('%s %s', data.firstname, data.lastname),
            isMenuHeader = true
        },
        {
            header = 'CID',
            txt = data.citizenid,
            isMenuHeader = true
        },
        {
            header = Config.Locales.amount,
            txt = '$' .. data.amount,
            isMenuHeader = true
        },
        {
            header = Config.Locales.status,
            txt = data.status or 'unpaid',
            isMenuHeader = true
        },
        {
            header = Config.Locales.reason,
            txt = data.reason,
            isMenuHeader = true
        },
        {
            header = Config.Locales.confiscated_weapon,
            txt = data.confiscated_weapon or Config.Locales.none,
            isMenuHeader = true
        },
        {
            header = Config.Locales.prison_time,
            txt = data.prison_time or Config.Locales.none,
            isMenuHeader = true
        },
        {
            header = Config.Locales.issued_by,
            txt = data.officername,
            isMenuHeader = true
        },
        {
            header = Config.Locales.date_issued,
            txt = FormatDate(data.date),
            isMenuHeader = true
        }
    }

    -- Add delete option for authorized personnel
    if RSGCore.Functions.GetPlayerData().job.isboss then
        table.insert(detailMenu, {
            header = Config.Locales.delete_fine,
            txt = Config.Locales.delete_fine_desc,
            params = {
                event = 'pure-mdt:client:deleteFine',
                args = data
            }
        })
    end

    table.insert(detailMenu, {
        header = Config.Locales.back,
        txt = '',
        params = {
            event = 'pure-mdt:client:showSearchResults',
            args = {results = {data}, searchType = 'fines'}
        }
    })

    exports['rsg-menu']:openMenu(detailMenu)
end)

-- Delete Fine
RegisterNetEvent('pure-mdt:client:deleteFine', function(data)
    TriggerServerEvent('pure-mdt:server:deleteFine', data.id)
end)

-- View Weapon Details
RegisterNetEvent('pure-mdt:client:viewWeaponDetails', function(data)
    local detailMenu = {
        {
            header = data.weapon_name,
            isMenuHeader = true
        },
        {
            header = Config.Locales.weapon_owner,
            txt = data.owner_name,
            isMenuHeader = true
        },
        {
            header = 'CID',
            txt = data.citizenid,
            isMenuHeader = true
        },
        {
            header = Config.Locales.serial_number,
            txt = data.serial_number,
            isMenuHeader = true
        },
        {
            header = Config.Locales.registered_by,
            txt = data.registered_by,
            isMenuHeader = true
        },
        {
            header = Config.Locales.registration_date,
            txt = FormatDate(data.date),
            isMenuHeader = true
        }
    }

    -- Add delete option for authorized personnel
    if RSGCore.Functions.GetPlayerData().job.isboss then
        table.insert(detailMenu, {
            header = Config.Locales.delete_registration,
            txt = Config.Locales.delete_registration_desc,
            params = {
                event = 'pure-mdt:client:deleteWeaponRegistration',
                args = data
            }
        })
    end

    table.insert(detailMenu, {
        header = Config.Locales.back,
        txt = '',
        params = {
            event = 'pure-mdt:client:showSearchResults',
            args = {results = {data}, searchType = 'weapons'}
        }
    })

    exports['rsg-menu']:openMenu(detailMenu)
end)

-- Delete Weapon Registration
RegisterNetEvent('pure-mdt:client:deleteWeaponRegistration', function(data)
    TriggerServerEvent('pure-mdt:server:deleteWeaponRegistration', data.serial_number)
end)

-- Return to Main Menu
RegisterNetEvent('pure-mdt:client:openMainMenu', function()
    OpenMainMenu()
end)