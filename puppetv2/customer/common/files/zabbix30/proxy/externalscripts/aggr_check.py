#!/usr/bin/python

URL  = 'https://zabbix-rw.esbu.lab.com.au/zabbix'
USER = 'svc_api'
PASS = 'AP!@ccess'


from zabbix.api import ZabbixAPI
import sys
import os

def check_argv(argv):
  if len(argv) != 4:
    print 'NOT_SUPPORTED'
    exit(255)
  return;

def zabbix_connect(zbx_url, zbx_user, zbx_pass):
  try:
    res = ZabbixAPI(url=zbx_url, user=zbx_user, password=zbx_pass)
    return res
  except:
    print "NOT_SUPPORTED"
    exit(254)

  
def items_calc(zapi, argv):
  try:

    host     = argv[1]
    item_key = argv[2]

    if argv[3]:
      func   = argv[3]
    else:
      func   = 'sum'

    values_res = zapi.do_request('item.get',
    {
      'host':   argv[1],
      'output': [ 'key_','lastvalue'],
      'search': {
        'key_': argv[2]
      }
    })

    last_values_list = [float(results['lastvalue']) for results in values_res['result'] if not (os.path.basename(argv[0]) in results['key_'])]

    if func == 'sum':
      res = sum(last_values_list)
    elif func == 'max':
      res = max(last_values_list)
    elif func == 'min':
      res = min(last_values_list)
    else:
      res = 0

    return int(res);
    
  except:
    print "NOT_SUPPORTED"
    exit(253)




check_argv(sys.argv)
zapi = zabbix_connect(URL,USER,PASS)
print items_calc(zapi,sys.argv)
zapi.user.logout()
