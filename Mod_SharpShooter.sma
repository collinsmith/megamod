#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <cstrike>
#include <csdm>
#include <colorchat>

static const Plugin [] = "Sharpshooter";
static const Author [] = "Tirant";
static const Version[] = "0.0.1";

#define null -1
#define WEAPON_DELAY 45

//static bool:g_bRoundStarted;
static g_iTicker;

static g_szSSWeapon[32];
static bool:g_iWeaponPicked[CSW_P90+1];
static g_iCurWeapon = null;
static g_iExcludedWeapons[] = {
	2,
	CSW_KNIFE,
	CSW_C4,
	CSW_SMOKEGRENADE,
	CSW_GALI,
	CSW_FLASHBANG
}

static const g_szRandomWeapon[] = "megamod/SharpShooter/random_weapon.wav";
static const g_szCountdown   [][] = {
	"megamod/SharpShooter/one.wav",
	"megamod/SharpShooter/two.wav",
	"megamod/SharpShooter/three.wav",
	"megamod/SharpShooter/four.wav",
	"megamod/SharpShooter/five.wav"
}

public plugin_precache() {
	precache_sound(g_szRandomWeapon);
	for (new i = 0; i < sizeof g_szCountdown; i++) {
		precache_sound(g_szCountdown[i]);
	}
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
		
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0");
	register_event("AmmoX", 	"ev_AmmoX", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10");
	
	register_logevent("logevent_round_start",2, 	"1=Round_Start");
	register_logevent("logevent_round_end", 2, 	"1=Round_End");
}

public ev_RoundStart() {
	//...
}

public ev_AmmoX(id) {
	set_pdata_int(id, 376 + read_data(1), 200, 5);
}

public logevent_round_start() {
	resetRandomWeapon();
	if (!task_exists(1337)) {
		set_task(1.0, "countdown", 1337, _, _, "b");
	}
}

public logevent_round_end() {
	//...
}

public countdown() {
	g_iTicker--;
	new mins = g_iTicker/60, secs = g_iTicker%60;
	if (g_iTicker >= 0) {
		client_print(0, print_center, "%d:%s%d", mins, (secs < 10 ? "0" : ""), secs);
	}
	
	if (g_iTicker < 1) {
		resetRandomWeapon();
		return PLUGIN_HANDLED;
	} else if (g_iTicker < 6) {
		client_cmd(0, "spk %s", g_szCountdown[g_iTicker-1]);
	}
	return PLUGIN_CONTINUE;
}

resetRandomWeapon() {
	g_iTicker = WEAPON_DELAY+1;
	selectRandomWeapon();
}

selectRandomWeapon() {
	new iRand = null;
	while (iRand == null) {
		iRand = random_num(CSW_P228, CSW_P90);
		if (iRand == g_iCurWeapon || g_iWeaponPicked[iRand]) {
			iRand = null;
			continue;
		}
		
		for (new i = 0; i < sizeof g_iExcludedWeapons; i++) {
			if (iRand == g_iExcludedWeapons[i]) {
				iRand = null;
				break;
			}
		}
	}
	
	g_iCurWeapon = iRand;
	g_iWeaponPicked[g_iCurWeapon] = true;
	get_weaponname(g_iCurWeapon, g_szSSWeapon, charsmax(g_szSSWeapon));
	
	static szWeaponName[32];
	copy(szWeaponName, charsmax(szWeaponName), g_szSSWeapon);
	replace(szWeaponName, charsmax(szWeaponName), "weapon_", "");
	strtoupper(szWeaponName);
	
	client_cmd(0, "spk %s", g_szRandomWeapon);
	set_hudmessage(0, 255, 255, -1.0, 0.4, 0, 0.0, 6.0, 0.0, 0.0, 2);
	show_hudmessage(0, "The %s has become the new weapon of choice!", szWeaponName);
	client_print_color(0, DontChange, "^3The new weapon of choice is the ^4%s", szWeaponName);
	
	giveRandomWeapon(0);
}

giveRandomWeapon(id) {
	if (g_iCurWeapon != null) {
		if (id == 0) {
			static iPlayers[32], iCount;
			get_players(iPlayers, iCount, "a");
			for (new i = 0; i < iCount; i++) {
				fm_strip_user_weapons(iPlayers[i]);
				fm_give_item(iPlayers[i], g_szSSWeapon);
				cs_set_user_bpammo(iPlayers[i], g_iCurWeapon, 200);
			}
		} else {
			fm_strip_user_weapons(id);
			fm_give_item(id, g_szSSWeapon);
			cs_set_user_bpammo(id, g_iCurWeapon, 200);
		}
	}
}

public csdm_RoundRestart() {
	
}

public csdm_PostSpawn(id) {
	giveRandomWeapon(id);
}
