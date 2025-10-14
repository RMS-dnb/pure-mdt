Config = {}

-- Discord Webhooks
Config.Webhooks = {
    enable = true,
    fines = {
        new = "", -- New fines created
        paid = "", -- Fines being paid
        deleted = "" -- Fines being deleted
    },
    weapons = {
        new = "", -- New weapon registrations
        deleted = "" -- Weapon registrations deleted
    }
}

Config.WebhookColors = {
    new = 65280,      -- Green
    paid = 65535,     -- Yellow
    deleted = 16711680 -- Red
}

-- Commands
Config.Command = 'MDT' -- Command to open MDT
Config.CheckFine = 'fine' -- Command to check personal fines

-- Jobs allowed to use MDT
Config.AllowedJobs = {
    ['police'] = true,
    ['policebusy'] = true
}

-- Fine Settings
Config.MaxFineAmount = 1000
Config.MinFineAmount = 5
Config.FineDistance = 3.0 -- Distance to issue fine

-- General Settings
Config.Debug = false -- Set to true to enable debug prints
Config.AdminGrade = 3 -- Minimum grade for admin commands

-- Database Tables
Config.Tables = {
    fines = 'mdt_fines',
    weapons = 'mdt_weapons'
}

-- Complete Locales
Config.Locales = {
    -- General
    no_permission = 'You do not have permission for this action',
    no_player_nearby = 'No player nearby',
    success = 'Success',
    error = 'Error',
    close = 'Close',
    submit = 'Submit',
    cancel = 'Cancel',
    back = 'Back',
    close_menu = 'Close menu',
    confirm = 'Confirm',
    confiscated_weapon = 'Confiscated weapon',
    prison_time = 'Prison time',
    none = 'None',
    
    -- MDT Menu
    mdt_title = 'Sheriff MDT System',
    mdt_subtitle = 'Law Enforcement Database',
    
    -- Fine Management
    fine_management = 'Fine Management',
    create_fine = 'Create Fine',
    search_fines = 'Search Fines',
    fine_amount = 'Fine Amount',
    fine_desc = 'Create a new fine',
    fine_created = 'Fine created successfully',
    fine_paid = 'Fine paid successfully',
    fine_deleted = 'Fine deleted successfully',
    fine_received = 'You received a fine',
    insufficient_funds = 'Insufficient funds to pay the fine',
    first_name = 'First Name',
    last_name = 'Last Name',
    reason = 'Reason',
    amount = 'Amount',
    invalid_amount = 'Invalid fine amount',
    fine_details = 'Fine Details - $%s',
    delete_fine = 'Delete Fine',
    delete_fine_desc = 'Permanently delete the fine record',
    
    -- Weapon Registration
    weapon_registration = 'Weapon Registration',
    register_weapon = 'Register New Weapon',
    search_weapons = 'Search Weapons',
    weapon_owner = 'Weapon Owner',
    weapon_name = 'Weapon Name',
    serial_number = 'Serial Number',
    weapon_registered = 'Weapon registered successfully',
    weapon_exists = 'Weapon is already registered',
    search_by_serial = 'Search by Serial Number',
    search_by_owner = 'Search by Owner Name',
    search_current_weapon = 'Search Current Weapon',
    search_current_desc = 'Search database for equipped weapon',
    no_weapon_equipped = 'No weapon equipped',
    no_serial_found = 'No weapon serial number found',
    delete_registration = 'Delete Registration',
    delete_registration_desc = 'Permanently delete weapon registration',
    weapon_registration_deleted = 'Weapon registration deleted successfully',
    confirm_registration = 'Confirm weapon registration',
    confirm_desc = 'Confirm weapon registration details',
    
    -- Search and Selection
    search_results = 'Search Results',
    no_results = 'No results found',
    search_name = 'Search by Name',
    enter_search = 'Enter search term',
    search_citizen = 'Search',
    select_citizen = 'Select Citizen',
    search = 'Search',
    
    -- Details and Information
    date_issued = 'Date Issued',
    issued_by = 'Issued By',
    location = 'Location',
    registered_by = 'Registered By',
    registration_date = 'Registration Date',
    owner = 'Owner',
    status = 'Status',
    
    -- Fine Payment
    your_fines = 'Your Unpaid Fines',
    no_unpaid_fines = 'No unpaid fines',
    pay_fine = 'Pay Fine',
    pay_fine_desc = 'Pay $%s to settle the fine',
    confirm_payment = 'Confirm Payment - $%s',
    type_confirm = 'Type "confirm" to pay the fine',
    pay = 'Pay',
    fine_paid_success = 'Fine paid successfully',
    
    -- Weapon Details
    select_weapon_owner = 'Select Weapon Owner',
    weapon_details = 'Weapon Details',
    current_weapon = 'Current Weapon',
    
    -- Confirmation
    confirm_delete = 'Confirm Deletion',
    confirm_delete_desc = 'Are you sure you want to delete this?',
    operation_success = 'Operation completed successfully',
    operation_failed = 'Operation was not successful',
    
    -- Admin
    admin_reset = 'Reset Database',
    admin_reset_success = 'MDT database reset successfully',
    
    -- Errors
    error_no_data = 'No data available',
    error_invalid_input = 'Invalid input entered',
    error_db = 'Database error occurred',
    error_permission = 'You do not have permission for this'
}
