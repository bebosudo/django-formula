{% for site in salt["pillar.get"]("django_sites", []) %}
{% set local_path, venv_dir = "$HOME/.local/bin", site.get("virtualenv_dir", site.install_dir + "/.venv") %}

Apply migrations for site {{ site.name }}:
  cmd.run:
    - name: {{ venv_dir }}/bin/python {{ site.install_dir }}/manage.py migrate
    - runas: {{ site.user_name }}
    - require:
      - Install requirements file for site {{ site.name }} if requested
      {% if site.get("settings") or site.get("settings_source_file") %}
      - Build settings file from template for site {{ site.name }}
      {% endif %}
    - require:
      - Setup django systemd gunicorn service for site {{ site.name }}
    - onchanges:
      - {{ site.name }} download latest from git


{% if site.get("setup_script") %}
Run setup script for site {{ site.name }}:
  cmd.run:
    - name: {{ venv_dir }}/bin/python {{ site.install_dir }}/{{ site.setup_script }}
    - runas: {{ site.user_name }}
    - onchanges:
      - Apply migrations for site {{ site.name }}
{% endif %}


{% if site.get("static_subdirs") %}
{% for dir in site.static_subdirs %}
Create subdirectory {{ dir }} for site {{ site.name }}:
  file.directory:
    - name: {{ site.install_dir }}/{{ dir }}
    - user: {{ site.user_name }}
    - group: nginx
    - makedirs: True
{% endfor %}
{% endif %}


{% if site.get("collectstatic") %}
Run the collectstatic script for site {{ site.name }}:
  cmd.run:
    - name: cd {{ site.install_dir }} && {{ venv_dir }}/bin/python manage.py collectstatic --noinput
    - runas: {{ site.user_name }}
    - onchanges:
      - {{ site.name }} download latest from git
{% endif %}


{% if site.get("users") %}
Add users for site {{ site.name }} using custom script:
  file.managed:
    - name: {{ venv_dir }}/setup_users.py
    - user: {{ site.user_name }}
    - contents: |
        from django.contrib.auth import get_user_model
        User = get_user_model()
        {% for user in site.get("users", []) %}
        try:
            User.objects.get(username="{{ user.name }}").delete()
        except User.DoesNotExist:
            pass

        {% if user.get("is_superuser", False) %}
        User.objects.create_superuser(
        {% else %}
        User.objects.create_user(
        {% endif %}
            username="{{ user.name }}",
            password="{{ user.password }}",
            {% if user.get("email") %}
            email="{{ user.email }}",
            {% endif %}
        )

        {% endfor %}

  cmd.run:
    - name: {{ venv_dir }}/bin/python {{ site.install_dir }}/manage.py shell < {{ venv_dir }}/setup_users.py
    - runas: {{ site.user_name }}
    - onchanges:
      - Apply migrations for site {{ site.name }}
{% endif %}


{% endfor %}
