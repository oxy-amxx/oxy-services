#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN_NAME "Who x Models"

#define SKINS_FILE "addons/amxmodx/configs/oxy_skins.ini"
#define MODEL_LEN  32
#define GROUP_NAME_LEN 32
#define FLAG_STR_LEN   32

enum GroupInfo { gName[GROUP_NAME_LEN], gFlags[FLAG_STR_LEN] }

new const g_adminGroups[][GroupInfo] =
{
    { "Founder",           "abcdefghijklmnopqruvt" },
    { "Owner",             "bcdefghijmnopr"        },
    { "Co-Owner",          "bcdefhijmnopr"         },
    { "Supervisor",        "bcdefhijmnop"          },
    { "Moderator-Global",  "bcdefhijmno"           },
    { "Super-Moderator",   "bcdefhijmn"            },
    { "Moderator",         "bcdefijm"              },
    { "Helper",            "bcdefijq"              },
    { "VIP",               "t"                     },
    { "Slot",              "b"                     }
};

new g_flags_bits[sizeof g_adminGroups];
new g_model_T[sizeof g_adminGroups][MODEL_LEN];
new g_model_CT[sizeof g_adminGroups][MODEL_LEN];

public plugin_init()
{
    register_plugin(PLUGIN_NAME, "0.6", "oxy");

    register_clcmd("say /who", "cmdWho");
    RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

    cache_group_flags();
}

public plugin_precache()
{
    load_models();
}

stock cache_group_flags()
{
    new i;
    for (i = 0; i < sizeof g_adminGroups; i++)
        g_flags_bits[i] = read_flags(g_adminGroups[i][gFlags]);
}

public cmdWho(idx)
{
    new menu = menu_create("\rName Server -\w Admins Online^nName\r |\w Group", "menu_handler");

    new players[32], num;
    get_players(players, num, "ch");

    new i, x, id, count, flags;
    new len[128], name[32], num2[6];

    if (getAdmins())
    {
        count = 0;
        for (i = 0; i < sizeof g_adminGroups; i++)
        {
            for (x = 0; x < num; x++)
            {
                id = players[x];
                if (!is_user_connected(id))
                    continue;

                flags = get_user_flags(id);
                if (flags & g_flags_bits[i])
                {
                    count++;
                    num_to_str(count, num2, charsmax(num2));
                    get_user_name(id, name, charsmax(name));
                    formatex(len, charsmax(len), "%s\r |\w %s", name, g_adminGroups[i][gName]);
                    menu_additem(menu, len, num2);
                }
            }
        }
        if (!count)
            menu_additem(menu, "No Admins online.", "1");
    }
    else
    {
        menu_additem(menu, "No Admins online.", "1");
    }

    menu_display(idx, menu, 0);
    return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    menu_destroy(menu);
    return PLUGIN_CONTINUE;
}

stock load_models()
{
    if (!file_exists(SKINS_FILE))
        return;

    new file = fopen(SKINS_FILE, "r");
    if (!file)
    {
        log_amx("(%s) Nu am gasit fisierul: %s!", PLUGIN_NAME, SKINS_FILE);
        return;
    }

    new line[64], grad[32], model[MODEL_LEN], team[8];
    new path[64];
    new i, isCT;

    while (fgets(file, line, charsmax(line)))
    {
        trim(line);
        if (line[0] == ';' || !line[0])
            continue;

        grad[0] = 0;
        model[0] = 0;
        team[0] = 0;

        parse(line, grad, charsmax(grad), model, charsmax(model), team, charsmax(team));
        if (!grad[0] || !model[0] || !team[0])
            continue;

        isCT = (team[0] == 'C' || team[0] == 'c');

        for (i = 0; i < sizeof g_adminGroups; i++)
        {
            if (!equal(g_adminGroups[i][gName], grad))
                continue;

            if (isCT) formatex(g_model_CT[i], charsmax(g_model_CT[]), model);
            else      formatex(g_model_T[i],  charsmax(g_model_T[]),  model);

            formatex(path, charsmax(path), "models/player/%s/%s.mdl", model, model);
            if (file_exists(path))
                precache_model(path);
            else
            {
                if (isCT) g_model_CT[i][0] = 0;
                else      g_model_T[i][0]  = 0;
            }
            break;
        }
    }
    fclose(file);
}

public player_spawn(id)
{
    if (!is_user_connected(id) || !is_user_alive(id))
        return;

    new i, flags = get_user_flags(id);
    new CsTeams:team = cs_get_user_team(id);

    for (i = 0; i < sizeof g_adminGroups; i++)
    {
        if (!(flags & g_flags_bits[i]))
            continue;

        if (team == CS_TEAM_CT)
        {
            if (g_model_CT[i][0])      { set_player_model(id, g_model_CT[i]); break; }
            else if (g_model_T[i][0])  { set_player_model(id, g_model_T[i]);  break; }
        }
        else if (team == CS_TEAM_T)
        {
            if (g_model_T[i][0])       { set_player_model(id, g_model_T[i]);  break; }
            else if (g_model_CT[i][0]) { set_player_model(id, g_model_CT[i]); break; }
        }
    }
}

stock set_player_model(id, const model[])
{
    if (!is_user_connected(id) || !model[0])
        return;
    cs_set_user_model(id, model);
}

stock bool:getAdmins()
{
    new players[32], num;
    get_players(players, num, "ch");

    new i, x, id, flags;
    for (i = 0; i < sizeof g_adminGroups; i++)
    {
        for (x = 0; x < num; x++)
        {
            id = players[x];
            if (!is_user_connected(id))
                continue;

            flags = get_user_flags(id);
            if (flags & g_flags_bits[i])
                return true;
        }
    }
    return false;
}
