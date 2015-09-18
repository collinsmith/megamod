
#include <amxmodx>

#define PLUGIN    "Timeleft as Roundtime"
#define AUTHOR    "AcidoX (idea), Arkshine and joaquimandrade"
#define VERSION    "1.2"

new gMsgidShowTimer;
new bool:isRoundTime;

public plugin_init ()
{
	register_plugin( PLUGIN, VERSION, AUTHOR);
	//register_cvar( "TimeleftRoundtime",VERSION,FCVAR_SERVER|FCVAR_SPONLY )
	register_message( get_user_msgid( "RoundTime" ),"Event_RoundTime" );
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0");
	register_event( "BombDrop", "Event_BombDropped", "a", "4=1" );
	register_logevent("logevent_round_start",2, 	"1=Round_Start")
	register_logevent("logevent_round_end", 2, 	"1=Round_End")
	gMsgidShowTimer = get_user_msgid( "ShowTimer" );
}

public ev_RoundStart() {
	isRoundTime = false;
}

public logevent_round_start() {
	isRoundTime = true;
}

public logevent_round_end() {
	isRoundTime = false;
}

public Event_RoundTime( const MsgId, const MsgDest, const MsgEnt )
{
	//new g_TimeLeft = get_timeleft()
	/*if (600 < g_TimeLeft) {
		if (g_TimeLeft < 606) {
			new szTemp[32]
			num_to_word(g_TimeLeft-600, szTemp, charsmax(szTemp))
			client_cmd(0, "spk fvox/%s.wav", szTemp)
			client_print(0, print_center, "%d", g_TimeLeft-600)
		}
	} else {
		set_msg_arg_int( 1, ARG_SHORT, g_TimeLeft );
	}*/
	if (isRoundTime) {
		set_msg_arg_int(1, ARG_SHORT, get_timeleft());
	}
}

public Event_BombDropped ()
{
	message_begin( MSG_BROADCAST, gMsgidShowTimer );
	message_end();
}
