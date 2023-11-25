#!/usr/bin/bash

rm -f ./authkey
vagrant up
sed -i 's/https:\/\/192.168.0.49:6443/https:\/\/127.0.0.1:6443/g' ~/.kube/config

#kubectl delete deployment coredns -n kube-system;kubectl delete svc coredns -n kube-system;
kubectl apply -f coredns.yaml;
#sudo sed -i "$ a\        '--cluster-dns=10.43.0.99' \\" /etc/systemd/system/k3s.service