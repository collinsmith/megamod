#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <cstrike>
#include <csdm>
#include <colorchat>
#include <round_terminator>

static const Plugin [] = "Gun Game";
static const Author [] = "Tirant";
static const Version[] = "0.0.1";

#define null -1
#define MAX_PLAYERS 32

static g_iWeaponLevel[MAX_PLAYERS+1];
static g_szCurWeapon[32];
static g_iWinner = null;

static g_iWeaponList[] = {
	CSW_P228,
	CSW_DEAGLE,
	CSW_ELITE,
	CSW_M3,
	CSW_XM1014,
	CSW_MP5NAVY,
	CSW_UMP45,
	CSW_P90,
	CSW_GALIL,
	CSW_FAMAS,
	CSW_AUG,
	CSW_M4A1,
	CSW_AK47,
	CSW_M249,
	CSW_SCOUT,
	CSW_AWP,
	CSW_G3SG1,
	CSW_KNIFE
}

static const g_szGainLevel[] = "megamod/GunGame/gain_level.wav";
static const g_szLoseLevel[] = "megamod/GunGame/lose_level.wav";
static const g_szRoundWin [] = "megamod/GunGame/round_win.mp3";

public plugin_precache() {
	precache_sound(g_szGainLevel);
	precache_sound(g_szLoseLevel);
	precache_sound(g_szRoundWin);
}

public plugin_init() {
	register_plugin(Plugin, Version, Author);
		
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0");
	register_event("AmmoX", 	"ev_AmmoX", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10");
	register_event("SendAudio", 	"ev_RoundDraw", "a", "%!MRAD_rounddraw");
	
	register_message(get_user_msgid("TextMsg"), "msgRoundEnd");
}

public client_connect(id) {
	g_iWeaponLevel[id] = 0;
}

public client_disconnect(id) {
	g_iWeaponLevel[id] = 0;
}

public ev_RoundStart() {
	client_cmd(0, "mp3 stop");
	arrayset(g_iWeaponLevel, 0, MAX_PLAYERS+1);
}

public ev_AmmoX(id) {
	set_pdata_int(id, 376 + read_data(1), 200, 5);
}

public ev_RoundDraw() {
	return PLUGIN_HANDLED;
}

public msgRoundEnd(const MsgId, const MsgDest, const MsgEntity) {
	static szMessage[128];
	get_msg_arg_string(2, szMessage, charsmax(szMessage))
	
	if (equal(szMessage, "#Round_Draw")) {
		static szPlayerName[32];
		get_user_name(g_iWinner, szPlayerName, charsmax(szPlayerName));
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 6.0, 0.1, 0.2, 1)
		show_hudmessage(0, "%s has won the round!", szPlayerName)
		client_print_color(0, DontChange, "^4%s ^3has won the round!", szPlayerName);
		set_msg_arg_string(2, "")
		client_cmd(0, "mp3 play sound/%s", g_szRoundWin);
		g_iWinner = null;
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public csdm_PostDeath(iKiller, iVictim, iHeadshot, const szWeapon[]) {
	if (!is_user_connected(iKiller)) {
		return PLUGIN_CONTINUE;
	}
	
	if (iKiller == iVictim || equal(szWeapon, "knife")) {
		client_cmd(iVictim, "spk %s", g_szLoseLevel);
		if (g_iWeaponLevel[iVictim] > 0) {
			g_iWeaponLevel[iVictim]--;
		}
	}
	
	get_weaponname(g_iWeaponList[g_iWeaponLevel[iKiller]], g_szCurWeapon, charsmax(g_szCurWeapon));
	replace(g_szCurWeapon, charsmax(g_szCurWeapon), "weapon_", "");
	if (equal(szWeapon, g_szCurWeapon)) {
		if (g_iWeaponLevel[iKiller] <= sizeof g_iWeaponList) {
			g_iWeaponLevel[iKiller]++;
			client_cmd(iKiller, "spk %s", g_szGainLevel);
			if (g_iWinner == null) {
				giveCurrentWeapon(iKiller);
			}
		}
	}
	
	fm_set_user_frags(iVictim, g_iWeaponLevel[iVictim]+1);
	fm_set_user_frags(iKiller, g_iWeaponLevel[iKiller]+1);
	return PLUGIN_CONTINUE;
}

public csdm_PostSpawn(id) {
	giveCurrentWeapon(id);
	fm_set_user_frags(id, g_iWeaponLevel[id]+1);
}

giveCurrentWeapon(id) {
	if (g_iWeaponLevel[id] >= sizeof g_iWeaponList) {
		g_iWinner = id;
		TerminateRound(RoundEndType_Draw);
	} else {
		fm_strip_user_weapons(id);
		fm_give_item(id, "weapon_knife");
		get_weaponname(g_iWeaponList[g_iWeaponLevel[id]], g_szCurWeapon, charsmax(g_szCurWeapon));
		fm_give_item(id, g_szCurWeapon);
		cs_set_user_bpammo(id, g_iWeaponList[g_iWeaponLevel[id]], 200);
		client_print_color(id, DontChange, "^3You are now on level ^4%d^3/^4%d", g_iWeaponLevel[id]+1, sizeof g_iWeaponList);
	}
}
