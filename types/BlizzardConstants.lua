---@meta
-- Blizzard-owned numeric constants and integer enum values.

-- Spellbook / talents
---@type integer
MAX_SKILLLINE_TABS = nil

-- Unit stat enum
---@type integer
LE_UNIT_STAT_STRENGTH = nil
---@type integer
LE_UNIT_STAT_AGILITY = nil
---@type integer
LE_UNIT_STAT_INTELLECT = nil

-- UI framework constants
---@type integer
UIDROPDOWNMENU_MAXLEVELS = nil
---@type integer
STATICPOPUP_NUMDIALOGS = nil
---@type integer
LE_SCRIPT_BINDING_TYPE_INTRINSIC_POSTCALL = nil

-- Quest / gossip enums
---@type integer
LE_QUEST_FACTION_HORDE = nil
---@type integer
GOSSIP_BUTTON_TYPE_TITLE = nil
---@type integer
GOSSIP_BUTTON_TYPE_OPTION = nil
---@type integer
GOSSIP_BUTTON_TYPE_ACTIVE_QUEST = nil
---@type integer
GOSSIP_BUTTON_TYPE_AVAILABLE_QUEST = nil

-- Scenario types
---@type integer
LE_SCENARIO_TYPE_CHALLENGE_MODE = nil
---@type integer
LE_SCENARIO_TYPE_PROVING_GROUNDS = nil
---@type integer
LE_SCENARIO_TYPE_USE_DUNGEON_DISPLAY = nil
---@type integer
LE_SCENARIO_TYPE_WARFRONT = nil

-- Game error enum values (LE_GAME_ERR_*)
---@type integer
LE_GAME_ERR_ZONE_EXPLORED = nil
---@type integer
LE_GAME_ERR_ZONE_EXPLORED_XP = nil
---@type integer
LE_GAME_ERR_NEWTAXIPATH = nil
---@type integer
LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S = nil
---@type integer
LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE = nil
---@type integer
LE_GAME_ERR_QUEST_ADD_KILL_SII = nil
---@type integer
LE_GAME_ERR_QUEST_ADD_FOUND_SII = nil
---@type integer
LE_GAME_ERR_QUEST_ADD_ITEM_SII = nil
---@type integer
LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII = nil
---@type integer
LE_GAME_ERR_QUEST_ALREADY_DONE = nil
---@type integer
LE_GAME_ERR_QUEST_ALREADY_DONE_DAILY = nil
---@type integer
LE_GAME_ERR_QUEST_ALREADY_ON = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_CAIS = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_EXPANSION = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_LOW_LEVEL = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_MISSING_ITEMS = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_NOT_ENOUGH_MONEY = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_SPELL = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_WRONG_RACE = nil
---@type integer
LE_GAME_ERR_QUEST_HAS_IN_PROGRESS = nil
---@type integer
LE_GAME_ERR_QUEST_LOG_FULL = nil
---@type integer
LE_GAME_ERR_QUEST_MUST_CHOOSE = nil
---@type integer
LE_GAME_ERR_QUEST_NEED_PREREQS = nil
---@type integer
LE_GAME_ERR_QUEST_NEED_PREREQS_CUSTOM = nil
---@type integer
LE_GAME_ERR_QUEST_ONLY_ONE_TIMED = nil
---@type integer
LE_GAME_ERR_QUEST_SESSION_RESULT_ALREADY_ACTIVE = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NOT_IN_PARTY_S = nil
---@type integer
LE_GAME_ERR_QUEST_ACCEPTED_S = nil
---@type integer
LE_GAME_ERR_QUEST_COMPLETE_S = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_BAG_FULL_S = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_MAX_COUNT_S = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_S = nil
---@type integer
LE_GAME_ERR_QUEST_FAILED_TOO_MANY_DAILY_QUESTS_I = nil
---@type integer
LE_GAME_ERR_QUEST_FORCE_REMOVED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PET_BATTLE_VICTORIES_PVP_II = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_ACCEPTED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_ALREADY_DONE_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_ALREADY_DONE_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_BUSY_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_CLASS_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_CLASS_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_CROSS_FACTION_RESTRICTED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_DEAD_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_DEAD_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_DECLINED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_DIFFERENT_SERVER_DAILY_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_DIFFERENT_SERVER_DAILY_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_EXPANSION_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_EXPANSION_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_HIGH_FACTION_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_HIGH_FACTION_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_HIGH_LEVEL_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_HIGH_LEVEL_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_INVALID_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_INVALID_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOG_FULL_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOG_FULL_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOW_FACTION_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOW_FACTION_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOW_LEVEL_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_LOW_LEVEL_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NEW_PLAYER_EXPERIENCE_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NEW_PLAYER_EXPERIENCE_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NOT_ALLOWED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NOT_DAILY_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NOT_GARRISON_OWNER_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_NOT_GARRISON_OWNER_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_ONQUEST_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_ONQUEST_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_PREREQUISITE_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_PREREQUISITE_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_RACE_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_RACE_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_SUCCESS_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_TIMER_EXPIRED_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_WRONG_COVENANT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_WRONG_COVENANT_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_WRONG_FACTION_S = nil
---@type integer
LE_GAME_ERR_QUEST_PUSH_WRONG_FACTION_TO_RECIPIENT_S = nil
---@type integer
LE_GAME_ERR_QUEST_REWARD_EXP_I = nil
---@type integer
LE_GAME_ERR_QUEST_REWARD_MONEY_S = nil
---@type integer
LE_GAME_ERR_QUEST_TURN_IN_FAIL_REASON = nil

-- Equipment manager
---@type integer
LE_GAME_ERR_EQUIPMENT_MANAGER_BAGS_FULL = nil
---@type integer
LE_GAME_ERR_EQUIPMENT_MANAGER_COMBAT_SWAP_S = nil
---@type integer
LE_GAME_ERR_EQUIPMENT_MANAGER_MISSING_ITEM_S = nil
