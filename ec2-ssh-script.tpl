Host {{ var.ssh_host_name }}
    HostName {{ var.ssh_host_name }}
    IdentityFile {{ var.ssh_identity_file }}
    User {{ var.ssh_user }}
Host *
    TCPKeepAlive yes
    ServerAliveInterval 120
