#include <amxmodx> 
#include <amxmisc>

new g_Ping[33]
new g_Samples[33]

// CVARS
new p_amx_hpk_ping, p_amx_hpk_check, p_amx_hpk_tests, p_amx_hpk_delay

public plugin_init()
{
  register_plugin("High Ping Kicker (Steam)","0.16.2","OLO/shadow")
  register_concmd("amx_hpk","cmdHpk",ADMIN_KICK,"- configures high_ping_kicker plugin")
  p_amx_hpk_ping = register_cvar("amx_hpk_ping","200")
  p_amx_hpk_check = register_cvar("amx_hpk_check","12")
  p_amx_hpk_tests = register_cvar("amx_hpk_tests","5")
  p_amx_hpk_delay = register_cvar("amx_hpk_delay","60")
  
  if ( get_pcvar_num( p_amx_hpk_check ) < 5 ) set_cvar_num( "amx_hpk_check" , 5 )
  if ( get_pcvar_num( p_amx_hpk_tests ) < 3 ) set_cvar_num( "amx_hpk_tests" , 3 )
}

public client_disconnect(id) 
  remove_task( id )

public client_putinserver(id) 
{    
    g_Ping[id] = 0 
    g_Samples[id] = 0

    new param[1]
    param[0] = id 

    if (get_pcvar_num(p_amx_hpk_tests) != 0) {
        set_task( float(get_pcvar_num(p_amx_hpk_delay)), "taskSetting", id, param , 1)
    }
    else {	    
        set_task( float(get_pcvar_num( p_amx_hpk_tests )) , "checkPing" , id , param , 1 , "b" )
    }
} 

public taskSetting(param[]) {
	new name[32]
	get_user_name(param[0],name,31)
	set_task( float(get_pcvar_num( p_amx_hpk_tests )) , "checkPing" , param[0] , param , 1 , "b" )
}

kickPlayer( id ) 
{ 
  new name[32],authid[32]
  get_user_name(id,name,31)
  get_user_authid(id,authid,31)
  server_cmd("kick #%d PING > %d", get_user_userid(id), get_pcvar_num(p_amx_hpk_ping));
//  client_cmd(id, "Connect 91.192.189.63:27018")
  log_amx("[HPK]: ^"%s^" was kicked due to highping ^"%d^"", name, (g_Ping[id] / g_Samples[id]))
}

public checkPing(param[]) 
{ 
  new id = param[ 0 ] 

  if (has_vip(id)) return

  new p, l 

  get_user_ping( id , p , l ) 

  g_Ping[ id ] += p
  ++g_Samples[ id ]

  if ( (g_Samples[ id ] > get_pcvar_num( p_amx_hpk_tests )) && (g_Ping[id] / g_Samples[id] > get_pcvar_num( p_amx_hpk_ping ))  )    
    kickPlayer(id) 
}

  
public cmdHpk(id,level,cid){
  if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED
    
  new ping[5]
  new check_arr[5]
  new tests_arr[5]
  new delay_arr[5]
  read_argv(1,ping,4)
  read_argv(2,check_arr,4)
  read_argv(3,tests_arr,4)
  read_argv(4,delay_arr,4)
  
  new check = str_to_num(check_arr)
  new tests = str_to_num(tests_arr)
  new delay = str_to_num(delay_arr)
  
  
  if ( check < 5 ) check = 5
  if ( tests < 3 ) tests = 3
  

  if (read_argc() > 1){
    set_cvar_string("amx_hpk_ping",ping)
  }
  if (read_argc() > 2) {
	set_cvar_num("amx_hpk_check",check)
  }
  if (read_argc() > 3) {
	set_cvar_num("amx_hpk_tests",tests)
  }
  if (read_argc() > 4) {
	  set_cvar_num("amx_hpk_delay",delay)
 }

//  console_print(id,"Syntax: amx_hpk <ping to get kicked> <checks before kicks> <time between checks> <delay before first check in sec.>")
//  console_print(id,"Current High_Ping_Kicker Settings:")
//  console_print(id,"Maxping: %d  Time between checks: %d Checkcount: %d Delay: %d",get_pcvar_num(p_amx_hpk_ping),get_pcvar_num(p_amx_hpk_check),get_pcvar_num(p_amx_hpk_tests),get_pcvar_num(p_amx_hpk_delay))
  return PLUGIN_HANDLED    
}
