{% for site in salt["pillar.get"]("django_sites", []) %}

# If a settings dictionary was defined in the pillar, use it to build up a settings file from
# a template; otherwise let the settings file in the repo handle its configuration.
{% if site.get("settings") or site.get("settings_source_file") %}
Build settings file from template for site {{ site.name }}:
  file.managed:
    - name: {{ site.install_dir }}/{{ site.settings_dir }}/settings.py
    - source: {{ site.get("settings_source_file", "salt://django/files/settings.py.j2") }}
    - user: {{ site.user_name }}
    - group: nginx
    - template: jinja
    {% if site.get("settings_source_enable_jinja", True) %}
    - defaults:
        site: {{ site }}
    {% endif %}
{% endif %}

{% if site.get("settings", {}).get("STATIC_ROOT") %}
Create the static directory for site {{ site.name }}:
  file.directory:
    - name: {{ site.install_dir}}/{{ site.settings.STATIC_ROOT }}
    - user: {{ site.user_name }}
    - group: nginx
    - makedirs: True
{% endif %}

{% endfor %}
