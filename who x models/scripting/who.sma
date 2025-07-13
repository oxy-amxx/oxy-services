#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>

#define SKINS_FILE "addons/amxmodx/configs/oxy_skins.ini"

new const g_groups[10][] = 
{
    "Founder",
    "Owner",
    "Co-Owner",
    "Supervisor",
    "Moderator-Global",
    "Super-Moderator",
    "Moderator",
    "Helper",
    "VIP",
    "Slot"
};

new const g_flags[10][] = 
{
    "abcdefghijklmnopqruvt", // Founder
    "bcdefghijmnopr",        // Owner
    "bcdefhijmnopr",         // Co-Owner
    "bcdefhijmnop",          // Supervizor
    "bcdefhijmno",           // Moderator Global
    "bcdefhijmn",            // Super-Moderator
    "bcdefijm",              // Moderator
    "bcdefijq",              // Helper
    "t",                     // VIP
    "b"                      // Slot
};

new g_models[13][32];

public plugin_init()
{
    register_plugin("Who", "0.4", "oxy");

    register_clcmd("say /who", "cmdWho");

    RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
}

public plugin_precache()
{
    load_models();
}

public cmdWho(idx)
{
    new menu = menu_create("\rName Server -\w Admins Online^nName\r |\w Group", "menu_handler");
    new players[32], num, id, count, len[128], name[32], num2[6];

    get_players(players, num);

    if(getAdmins())
    {
        for(new i = 0; i < sizeof g_groups; i++)
        {
            for(new x = 0; x < num; x++)
            {
                count++;
                id = players[x];
                if(get_user_flags(id) == read_flags(g_flags[i]))
                {
                    num_to_str(count, num2, 5);
                    get_user_name(id, name, charsmax(name));
                    formatex(len, charsmax(len), "%s\r |\w %s", name, g_groups[i]);
                    menu_additem(menu, len, num2);
                }
            }
        }
    }
    else
    {
        menu_additem(menu, "No Admins online.", "1");
    }

    menu_display(idx, menu, 0);
}

public menu_handler(id, menu, item)
{
    if(item == MENU_EXIT)
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
        log_amx("[who.amxx] [ERROR] Couldn't open %s!", SKINS_FILE);
        return;
    }

    log_amx("[INFO] Loading models from: %s...", SKINS_FILE);

    new line[64], grad[32], model[32];

    while (fgets(file, line, charsmax(line)))
    {
        trim(line);
        if (line[0] == ';' || !line[0])
            continue;

        parse(line, grad, charsmax(grad), model, charsmax(model));

        for (new i = 0; i < sizeof g_groups; i++)
        {
            if (equal(g_groups[i], grad))
            {
                formatex(g_models[i], charsmax(g_models[]), model);
                new model_path[64];
                formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model, model);
                
                if (file_exists(model_path)) 
                    precache_model(model_path);
                else 
                    g_models[i][0] = 0;
                break;
            }
        }
    }
    fclose(file);
}

public player_spawn(id)
{

    for (new i = 0; i < sizeof g_groups; i++)
    {
        if (get_user_flags(id) & read_flags(g_flags[i]) && g_models[i][0] != 0)
        {
            set_player_model(id, g_models[i]);
            break;
        }
    }
}

stock set_player_model(id, const model[]) 
{
    if (!is_user_connected(id) || model[0] == 0)
        return;

    cs_set_user_model(id, model);
}

stock bool:getAdmins()
{
    new players[32], num, id;
    get_players(players, num);

    for(new i = 0; i < sizeof g_groups; i++)
    {
        for(new x = 0; x < num; x++)
        {
            id = players[x];
            if(get_user_flags(id) == read_flags(g_flags[i]))
                return true;
        }
    }
    return false;
}
