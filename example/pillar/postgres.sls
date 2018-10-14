{% import_yaml "django_sites.sls" as django_sites %}

postgres:
  use_upstream_repo: True
  fromrepo: pgdg10,base
  version: "10"

  cluster:
    locale: en_GB.UTF-8
    encoding: UTF8

  postgresconf: |-
    listen_addresses = '127.0.0.1'  # listen only on the local interface; use single quote chars

  acls:
    - ["host", "all", "all", "127.0.0.1/32", "md5"]
    - ["host", "all", "all", "::1/128",      "md5"]


  {%- if salt["status.time"]|default(none) is callable %}
  config_backup: ".backup@{{ salt["status.time"]("%y-%m-%d_%H:%M:%S") }}"
  {%- endif %}

  # https://stackoverflow.com/a/16746185/
  {% set use_pg = {"foo": False} %}
  {% for site in django_sites.django_sites if site.get("enable_postgres", True) %}{{ use_pg.update({"foo": True}) | default("", True) }}{% endfor %}

  {% if use_pg["foo"] %}
  users:
    {% for site in django_sites.django_sites %}
    {% if site.get("enable_postgres", True) %}
    {{ site.get("db_user_name", site.user_name) }}:
      ensure: present
      password: "{{ site.db_user_pswd }}"
      createdb: False
      createroles: False
      createuser: False
      inherit: True
      replication: False
    {% endif %}
    {% endfor %}


  databases:
    {% for site in django_sites.django_sites %}
    {% if site.get("enable_postgres", True) %}
    {{ site.get("db_name", site.name) }}:
      owner: "{{ site.get("db_user_name", site.user_name) }}"
      template: "template0"
      lc_ctype: "{{ site.get("lc_ctype", "en_US.UTF-8") }}"
      lc_collate: "{{ site.get("lc_collate", "en_US.UTF-8") }}"
    {% endif %}
    {% endfor %}
  {% endif %}
