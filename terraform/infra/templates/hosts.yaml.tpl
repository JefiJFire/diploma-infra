all:
  hosts:
%{ for name, n in nodes ~}
    ${name}:
      ansible_host: ${n.public_ip}
      ip: ${n.private_ip}
      access_ip: ${n.private_ip}
%{ if n.label != "" ~}
      node_labels:
        role: ${n.label}
%{ endif ~}
%{ endfor ~}
  vars:
    ansible_user: ubuntu
    supplementary_addresses_in_ssl_keys:
      - ${master_ip}
  children:
    kube_control_plane:
      hosts:
%{ for name, n in nodes ~}
%{ if n.role == "master" ~}
        ${name}:
%{ endif ~}
%{ endfor ~}
    etcd:
      hosts:
%{ for name, n in nodes ~}
%{ if n.role == "master" ~}
        ${name}:
%{ endif ~}
%{ endfor ~}
    kube_node:
      hosts:
%{ for name, n in nodes ~}
%{ if n.role == "worker" ~}
        ${name}:
%{ endif ~}
%{ endfor ~}
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
