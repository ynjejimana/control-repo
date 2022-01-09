#!/usr/bin/env python
#place this file in /etc/zabbix/externalscripts
#on each kafka mirror server
#see https://wiki.lab.com.au/x/RBnQAQ
 
import os
import json
 
#stolen from https://stackoverflow.com/questions/800197/how-to-get-all-of-the-immediate-subdirectories-in-python
def get_immediate_subdirectories(a_dir):
    return [name for name in os.listdir(a_dir)
            if os.path.isdir(os.path.join(a_dir, name))]
 
def main():
    mirrordir = '/etc/kafka/mirror'
    json_data = {'data': []}

    if not os.path.isdir(mirrordir):
        quit('cannot access ' + mirrordir + ': No such directory')

    for location in get_immediate_subdirectories(mirrordir):
 
        consfile=mirrordir + '/' + location + '/consumer.properties'
        prodfile=mirrordir + '/' + location + '/producer.properties'
        log4jfile=mirrordir + '/' + location + '/log4j.properties'
 
        json_data['data'].append({
            '{#KMLOCATION}': location,
            '{#KMCONSFILE}': consfile,
            '{#KMPRODFILE}': prodfile,
            '{#KMLOG4JFILE}': log4jfile,
            })
 
    print(json.dumps(json_data))
 
if __name__ == "__main__":
    main()
