{% for site in salt["pillar.get"]("django_sites", []) %}
{% set local_path, venv_dir = "$HOME/.local/bin", site.get("virtualenv_dir", site.install_dir + "/.venv") %}

Install virtualenv package for site {{ site.name }}:
  cmd.run:
    - name: {{ site.get("python_exe", "python") }} -m pip install --user virtualenv
    - runas: {{ site.user_name }}
    - unless: PATH="{{ local_path }}:$PATH" which virtualenv


Create virtualenv for site {{ site.name }}:
  cmd.run:  # The virtualenv formula doesn't seem to allow specifying exec without absolute path.
    - name: PATH="{{ local_path }}:$PATH" virtualenv {{ venv_dir }}
    - runas: {{ site.user_name }}
    - prepend_path: {{ local_path }}
    - unless: '[ -d "{{ venv_dir }}" ]'
    - require:
      - Install virtualenv package for site {{ site.name }}
      - {{ site.name }} download latest from git


{% if site.get('requirements_file') %}
Install requirements file for site {{ site.name }}:
  cmd.run:
    - name: {{ venv_dir }}/bin/pip install -r {{ site.install_dir }}/{{ site.requirements_file }}
    - runas: {{ site.user_name }}
    - require:
      - Create virtualenv for site {{ site.name }}
      - {{ site.name }} download latest from git
{% endif %}


{% if site.get('pip_packages') %}
Install packages for site {{ site.name }}:
  cmd.run:
    - name: {{ venv_dir }}/bin/pip install {{ site.pip_packages | join(" ") }}
    - runas: {{ site.user_name }}
    - require:
      - Create virtualenv for site {{ site.name }}
      - {{ site.name }} download latest from git
{% endif %}

{% endfor %}
