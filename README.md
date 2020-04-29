remote_cloud
---

Bash script to interact with rclone and a preconfigured
remote through the argument actions available below:

```
usage: rcloud {option} [input] [output]

options:
  sync (y)          sync remote name and exit
  copy (cp)         input file to remote output
  remove (rm)       input file from remote path
  removedir (rmdir) input folder from remote path
  makedir (mkdir)   new input folder in remote path
  list (ls)         contents from input remote path
  link (l)          share link to input file or folder
  check (c)         differences between local and remote
  mount (m)         mount remote directory (*)
  umount (u)        stop remote mount syncing (*)
  remount (r)       try and refresh remote mount (*)
  status (s)        status for remote mount (*)
```

**Note:** arguments marked with an asterisk are EXPERIMENTAL rclone features.

This is of course NOT intended as a desktop cloud solution.

Tested with rclone v1.49.5 on linux/amd64 (go1.13.1).