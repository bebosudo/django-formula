include:
  - nginx.ng

# https://stackoverflow.com/a/42084804/
# There's a race condition between nginx and systemd, so introduce a little sleep.
/etc/systemd/system/nginx.service.d:
  file.directory:
    - require_in:
      - nginx.ng.service

set sleep before nginx:
  file.managed:
    - name: /etc/systemd/system/nginx.service.d/override.conf
    - contents: |
        [Service]
        ExecStartPost=/bin/sleep 0.1
    - require_in:
      - nginx.ng.service

  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: set sleep before nginx


# https://github.com/saltstack/salt/issues/14183#issuecomment-426565384
Restart nginx server:
  cmd.run:
    - name: systemctl restart nginx
