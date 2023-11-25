node default {
  class { 'vagrant_vm':
    hostname  => $::hostname,
    nodeip    => $::nodeip,
    masterip  => $::masterip,
    nodetype  => $::nodetype,
  }
}

class vagrant_vm (
  String $hostname,
  String $nodeip,
  String $masterip,
  String $nodetype,
) {
  exec { 'set_timezone':
    command => 'timedatectl set-timezone Europe/Madrid',
    path    => '/bin:/usr/bin',
  }

  file { '/vagrant':
    ensure => 'directory',
    path   => '/vagrant',
  }

  host { 'hostname_entry':
    ensure  => present,
    name    => $nodeip,
    ip    => $nodeip,
    host_aliases => $hostname,
  }

  file { '/etc/hosts':
    ensure  => present,
    path    => '/etc/hosts',
    content => "192.168.0.49 m\n192.68.0.48 m2\n192.168.0.47 m3\n192.168.0.41 w1\n192.168.0.42 w2\n192.168.0.43 w3\n",
  }

  file { '/usr/local/bin/k3s':
  ensure  => present,
  source  => '/vagrant/k3s',
  mode    => '0755',
  require => File['/vagrant'],
  }
  #regex
  if $nodetype =~ /^master/ {
    if $nodetype == 'master' {
      exec { 'configure_corosynckey':
        command => "sudo corosync-keygen ; sudo cp /etc/corosync/authkey /vagrant/authkey",
        path    => '/bin:/usr/bin',
        require => Exec['install_k3s_master'],
        #require => Exec['configure_pacemaker'],
      }
    } else {
      exec { 'configure_corosynckey':
        command => "cp /vagrant/authkey /etc/corosync/authkey;chmod 400 /etc/corosync/authkey",
        path    => '/bin:/usr/bin',
        require => Exec['install_k3s_master'],
        #require => Exec['configure_pacemaker'],
      }
    }

    exec { 'configure_corosyncconfaddr':
      command => "sed -i 's/bindnetaddr: 127.0.0.1/bindnetaddr: 192.168.0.0/' /etc/corosync/corosync.conf",
      path    => '/bin:/usr/bin',
      require => Exec['configure_corosynckey'],
    }

    exec { 'configure_corosyncconfnodes':
      command => "echo 'nodelist {\n  node {\n    ring0_addr: 192.168.0.49\n    name: primary\n    nodeid: 1\n  }\n  node {\n    ring0_addr: 192.168.0.48\n    name: secondary\n    nodeid: 2\n  }\nnode {\n    ring0_addr: 192.168.0.47\n    name: third\n    nodeid: 3\n  }\n}' >> /etc/corosync/corosync.conf",
      path    => '/bin:/usr/bin',
      require => Exec['configure_corosyncconfaddr'],
    }
    exec { 'enable_corosync':
      command => 'systemctl enable corosync',
      path    => '/bin:/usr/bin',
      require => Exec['configure_corosyncconfnodes'],
    }

    exec { 'start_corosync':
      command => 'systemctl restart corosync',
      path    => '/bin:/usr/bin',
      require => Exec['enable_corosync'],
    }

    if $nodetype == 'master' {
      exec { 'configure_highavailability':
        command => 'sudo crm configure property stonith-enabled=false ; sudo crm configure primitive FAILOVER-ADDR ocf:heartbeat:IPaddr2 params ip="192.168.0.50" nic="enp0s8" op monitor interval="10s"',
        #command => 'sudo crm configure property stonith-enabled=false ; sudo crm configure primitive FAILOVER-ADDR ocf:heartbeat:FloatIP params ip="192.168.0.50" nic="enp0s8" op monitor interval="10s"',
        path    => '/bin:/usr/bin',
        require => Exec['enable_corosync'],
        #require => Exec['start_corosync'],
      }
    }
  }



  if $nodetype == 'master' {
    exec { 'install_k3s_master':
      command => "env INSTALL_K3S_SKIP_DOWNLOAD=true /vagrant/install.sh server --cluster-init --token 'wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5' --flannel-iface enp0s8 --bind-address $nodeip --node-ip $nodeip --node-name $hostname --disable traefik --node-taint k3s-controlplane=true:NoExecute --cluster-dns=10.43.0.99", #--cluster-dns=10.43.0.99
      path    => '/bin:/usr/bin',
      require => File['/usr/local/bin/k3s'],
    }

    exec { 'copy_k3s_yaml':
      command     => 'cp /etc/rancher/k3s/k3s.yaml /vagrant',
      path        => '/bin:/usr/bin',
      refreshonly => true,
      subscribe   => Exec['install_k3s_master'],
    }

    
    
  } else {
      if $nodetype == 'masterReplica' {
      exec { 'install_k3s_master':
        command => "env INSTALL_K3S_SKIP_DOWNLOAD=true /vagrant/install.sh server --server https://$masterip:6443 --token 'wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5' --flannel-iface enp0s8 --bind-address $nodeip --node-ip $nodeip --node-name $hostname --disable traefik --node-taint k3s-controlplane=true:NoExecute",
        path    => '/bin:/usr/bin',
        require => File['/usr/local/bin/k3s'],
      }
       #exec { 'install_k3s_master':
       # command => "curl -sfL https://get.k3s.io | K3S_TOKEN='wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5' sh -s - server --server https://$masterip:6443 --token 'wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5' --flannel-iface enp0s8 --bind-address $nodeip --node-ip $nodeip --node-name $hostname --disable traefik --node-taint k3s-controlplane=true:NoExecute",
       # path    => '/bin:/usr/bin',
       # require => File['/usr/local/bin/k3s'],
       #}

      
    } else {
      exec { 'install_k3s_agent':
        command => "env INSTALL_K3S_SKIP_DOWNLOAD=true /vagrant/install.sh agent --server https://$masterip:6443 --token 'wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5' --node-ip $nodeip --node-name $hostname --flannel-iface enp0s8",
        path    => '/bin:/usr/bin',
        require => File['/usr/local/bin/k3s'],
      }
    }
  }
}
