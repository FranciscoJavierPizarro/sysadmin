#!/usr/bin/bash
for mv in {orouter4,o4ff{2..4}} 
do
    echo "Encendiendo la máquina $mv"
    virsh -c qemu+ssh://a821259@155.210.154.207/system start $mv
done
