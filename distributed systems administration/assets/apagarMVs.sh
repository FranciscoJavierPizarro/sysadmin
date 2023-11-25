#!/usr/bin/bash
for mv in {4..1}
do
ssh -6 -n a821259@2001:470:736b:4ff::${mv} "doas shutdown -h now"
    echo "Apagando internamente la máquina $mv"
done
sleep 10
for mv in {o4ff{2..4},orouter4} 
do
    virsh -c qemu+ssh://a821259@155.210.154.207/system destroy $mv --graceful
    echo "Apagando forzadamente la máquina $mv"
done
