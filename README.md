remote_cloud
---

Bash script to interact with rclone and a preconfigured
remote through the argument actions available below:

```
usage: rcloud {option} [input] [output]

options:
  sync (y)      sync remote name and exit
  copy (cp)     a specific file to remote
  link (l)      get share link to file or folder
  mount (m)     start sync and mount as folder
  umount (u)    stop rclone remote syncing
  remount (r)   try and refresh remote sync
  status (s)    status for rclone remote mount
  check (c)     differences between local and remote
```

This is of course NOT intended as a desktop cloud solution.

Tested with rclone v1.49.5 on linux/amd64 (go1.13.1).