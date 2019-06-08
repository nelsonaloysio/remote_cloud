remote_cloud
---

Bash script to interact with rclone and a preconfigured
remote through the argument actions available below:

```
usage: rcloud {option} [input] [output] [-s]

options:
  sync (y)      sync google remote and exit
  copy (cp)     a specific file to remote
  link (l)      get share link for a file or folder
  mount (m)     start sync and mount as folder
  umount (u)    stop rclone remote syncing
  remount (r)   try and refresh remote sync
  check (c)     status for rclone remote mount
```

This is of course NOT intended as a desktop cloud solution.