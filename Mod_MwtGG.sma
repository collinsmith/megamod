#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <cstrike>
#include <csdm>

static const Plugin [] = "Man with the Golden Gun";
static const Author [] = "Tirant";
static const Version[] = "0.0.1";

#define null -1
#define MAX_PLAYERS 32
#define GOLDEN_GUN CSW_DEAGLE

static g_iMaxPlayers;

static const g_szGoldenGunV[] = "models/megamod/MwtGG/v_deagle.mdl";
static const g_szGoldenGunP[] = "models/megamod/MwtGG/p_deagle.mdl";
static g_szGoldenGun[32];

static const g_szNewMwtGG[] = "megamod/MwtGG/new_man.wav";
static const g_szLostGG	 [] = "megamod/MwtGG/lost_gun.wav";

static g_iKills[MAX_PLAYERS+1];
static g_iGoldenGun = null;

public plugin_precache() {
	precache_model(g_szGoldenGunV);
	precache_model(g_szGoldenGunP);
	precache_sound(g_szNewMwtGG);
	precache_sound(g_szLostGG);
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	
	register_event("DeathMsg", 	"ev_playerDeath", "a", "1>0");
	register_event("CurWeapon", 	"ev_curWeapon", "be","1=1");
	register_event("AmmoX", 	"ev_AmmoX", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10")
	
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage")
	
	get_weaponname(GOLDEN_GUN, g_szGoldenGun, charsmax(g_szGoldenGun));
	
	g_iMaxPlayers = get_maxplayers();
}

public client_connect(id) {
	g_iKills[id] = 0;
}

public client_disconnect(id) {
	g_iKills[id] = 0;
	if (id == g_iGoldenGun) {
		selectNewRandomGunman();
	}
}

public ev_playerDeath() {
	new iKiller = read_data(1);
	new iVictim = read_data(2);
	
	if (iVictim == g_iGoldenGun) {
		setNewGunman(iKiller);
	}
}

public ev_curWeapon(id) {
	if (id != g_iGoldenGun || read_data(2) != GOLDEN_GUN) {
		return PLUGIN_CONTINUE;
	}
	
	set_pev(id, pev_viewmodel, 	engfunc(EngFunc_AllocString, g_szGoldenGunV));
	set_pev(id, pev_weaponmodel, 	engfunc(EngFunc_AllocString, g_szGoldenGunP));
	return PLUGIN_CONTINUE;
}

public ev_AmmoX(id) {
	set_pdata_int(id, 376 + read_data(1), 200, 5);
}

public selectNewRandomGunman() {
	removeOldGunman();
	new iPlayers[32], iCount;
	get_players(iPlayers, iCount, "a");
	if (!iCount) {
		set_task(1.0, "selectNewRandomGunman");
	} else {	
		setNewGunman(iPlayers[random_num(0, iCount-1)]);
	}
}

setNewGunman(id) {
	removeOldGunman();
	g_iGoldenGun = id;
	set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 6.0, 0.0, 0.0, 1);
	new szPlayerName[32];
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	show_hudmessage(0, "%s has the Golden Gun!", szPlayerName);
	show_hudmessage(id, "You have the Golden Gun!");
	giveWeapons(id, true);
	client_cmd(0, "spk %s", g_szNewMwtGG);
}

giveWeapons(id, bool:isGunman = false) {
	if (is_user_alive(id)) {
		fm_strip_user_weapons(id);
		fm_give_item(id, "weapon_knife");
		if (isGunman) {
			fm_give_item(id, g_szGoldenGun);
			cs_set_user_bpammo(id, GOLDEN_GUN, 200);
			fm_set_user_rendering(id, kRenderFxGlowShell, 218, 165, 32, kRenderNormal, 10);
		} else {
			fm_give_item(id, "weapon_p228");
			cs_set_user_bpammo(id, CSW_P228, 200);
			fm_set_user_rendering(id);
		}
	}
}

removeOldGunman() {
	if (g_iGoldenGun != null) {
		client_cmd(g_iGoldenGun, "spk %s", g_szLostGG);
		giveWeapons(g_iGoldenGun);
	}
}

public csdm_PostDeath(killer, victim, headshot, const weapon[]) {
	if (killer != victim && is_user_connected(killer)) {
		static szweapon[32];
		copy(szweapon, 31, g_szGoldenGun);
		replace(szweapon, 31, "weapon_", "");
		if (equal(weapon, szweapon)) {
			g_iKills[killer]++;
		}
	}
	
	fm_set_user_frags(killer, g_iKills[killer]);
	fm_set_user_frags(victim, g_iKills[victim]);
}

public csdm_PostSpawn(id) {
	if (!is_user_alive(id)) {
		return;
	}
	
	if (g_iGoldenGun == null) {
		setNewGunman(id);
	}
	
	giveWeapons(id, id == g_iGoldenGun);
	fm_set_user_frags(id, g_iKills[id]);
}

public ham_TakeDamage(iVictim, iUseless, iAttacker, Float:flDamage, damageBits) {
	if (iAttacker == g_iGoldenGun) {
		static iGun;
		if (iUseless <= g_iMaxPlayers && iUseless != 0) {
			iGun = get_user_weapon(iAttacker);
		} else {
			static classname[32];
			pev(iUseless, pev_classname, classname, charsmax(classname));
			if (equal(classname,"grenade")) {
				iGun = 4;
			} else if (!iUseless) {
				iGun = 2;
			}
		}
		
		if (iGun != GOLDEN_GUN) {
			return HAM_IGNORED;
		}
		
		SetHamParamFloat(4,flDamage*100.0);
	} else if (iVictim == g_iGoldenGun) {
		if (flDamage >= pev(iVictim, pev_health)) {
			fm_set_user_rendering(iVictim);
		}
	}
	
	return HAM_HANDLED;
}
