#cloud-config
write_files:
  - path: /config/startup-license.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      echo "Start automatic license activation..."
      tmsh modify sys global-settings gui-setup disabled
      tmsh modify sys ntp servers add { 0.pool.ntp.org 1.pool.ntp.org }
      tmsh modify sys dns name-servers add { 8.8.8.8 1.1.1.1 }
      tmsh save sys config
      tmsh install sys license registration-key ${f5_license_key}
      tmsh save sys config
      echo "BIG-IP license activated..."
runcmd:
  - [ bash, /config/startup-license.sh ]
