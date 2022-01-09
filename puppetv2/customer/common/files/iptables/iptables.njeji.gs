# Firewall configuration written by system-config-firewall
# Manual customization of this file is not recommended.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:COMMON-INPUT - [0:0]
:NJEJI-CUSTOM-FW-INPUT - [0:0]
:NTT-INPUT - [0:0]
:LOGACCEPT - [0:0]
-A INPUT -j COMMON-INPUT
-A INPUT -j NTT-INPUT
-A INPUT -j NJEJI-CUSTOM-FW-INPUT
# LOG and ACCEPT everything else
-A INPUT -j LOGACCEPT
-A COMMON-INPUT -m state --state INVALID -j DROP
-A COMMON-INPUT -i lo -j ACCEPT
-A COMMON-INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A COMMON-INPUT -p icmp -m icmp --fragment -j DROP
-A COMMON-INPUT -p icmp -m icmp --icmp-type 3/4 -j ACCEPT
-A COMMON-INPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW -m limit --limit 5/s --limit-burst 5 -j ACCEPT
-A COMMON-INPUT -p icmp -m icmp --icmp-type any -j DROP
#-A COMMON-INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
-A COMMON-INPUT -p tcp -m tcp --syn --dport 22 -j LOG --log-prefix="[iptables] SSHD "
-A COMMON-INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A NTT-INPUT -p tcp -m tcp -s 172.16.40.0/24 --dport 10050 -j ACCEPT
-A NTT-INPUT -p tcp -m tcp -s 172.16.40.0/24 --dport 10051 -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p esp -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p ah -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 81 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 82 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p udp -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -s 224.0.0.0/4 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -d 224.0.0.0/4 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -s 240.0.0.0/5 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -m pkttype --pkt-type multicast -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -m pkttype --pkt-type broadcast -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p udp -m udp --dport 123 -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p udp -m udp --dport 161 -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p udp -m udp --dport 162 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 389 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 444 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 636 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 639 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 686 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 1521 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 1527 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 3060 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 3131 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 3872 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4443 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4444 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4445 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4446 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4848 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4899 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4900 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 4901 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 5162 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 5556 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 5557 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 5575 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m multiport --dports 5800:6700 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 6701 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 6707 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7000 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m multiport --dports 7001:7006 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7008 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7009 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7012 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7013 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7101 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7102 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7103 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7104 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7199 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7201 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7270 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7272 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7273 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7450 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7499 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7500 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7501 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7777 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7778 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 7890 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8001 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8002 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8044 -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
#-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8090 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m multiport --dports 8080:8090 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8101 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8102 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8180 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8181 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8280 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8281 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8282 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8443 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 8444 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m multiport --dports 9000:9100 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 9160 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 9703 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 9704 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 9804 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 11211 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14000 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14001 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14100 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14101 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14942 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 14943 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 18089 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 19000 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 19013 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 19043 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 19080 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 19999 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 28002 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m multiport --dports 30000:30100 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 35080 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 35080 -j ACCEPT
-A NJEJI-CUSTOM-FW-INPUT -p tcp -m tcp --dport 61616 -j ACCEPT
-A LOGACCEPT -m state --state NEW -j LOG --log-prefix="[iptables] LOGACCEPT "
-A LOGACCEPT -j ACCEPT
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT

