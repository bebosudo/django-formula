{% for site in salt["pillar.get"]("django_sites", []) %}
{% set venv_dir = site.get("virtualenv_dir", site.install_dir + "/.venv") %}

Setup django systemd gunicorn service for site {{ site.name }}:
  file.managed:
    - name: /etc/systemd/system/gunicorn_{{ site.name }}.service
    - source: salt://django/files/gunicorn.service.j2
    - template: jinja
    - defaults:
        site: {{ site }}
    - context:
        venv_dir: {{ venv_dir }}


Set correct write permissions to access log file for site {{ site.name }}:
  file.managed:
    - name: /var/log/access_{{ site.name }}.log
    - user: {{ site.user_name }}
    - group: nginx

Set correct write permissions to error log file for site {{ site.name }}:
  file.managed:
    - name: /var/log/error_{{ site.name }}.log
    - user: {{ site.user_name }}
    - group: nginx


Restart gunicorn service for site {{ site.name }}:
  service.running:
    - name: gunicorn_{{ site.name }}
    - enable: True

  # https://github.com/saltstack/salt/issues/14183#issuecomment-426565384
  cmd.run:
    - name: systemctl daemon-reload && systemctl restart gunicorn_{{ site.name }}

{% endfor %}
