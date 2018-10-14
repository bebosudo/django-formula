{% for site in salt["pillar.get"]("django_sites", []) %}

Create directory {{ site.install_dir }} with permissions for user {{ site.user_name }}:
  file.directory:
    - name: {{ site.install_dir }}
    - user: {{ site.user_name }}
    - group: nginx
    - makedirs: True


{{ site.name }} download latest from git:
  git.latest:
    - name: {{ site.git_address }}
    - rev: {{ site.get("rev", "HEAD") }}
    - target: {{ site.install_dir }}
    - branch: {{ site.get("branch", "master") }}
    - user: {{ site.user_name }}
    - force_clone: True
    - force_reset: True
    # - force_checkout: True
    - require:
      - Create directory {{ site.install_dir }} with permissions for user {{ site.user_name }}
    - require_in:
      - Build settings file from template for site {{ site.name }}

{% endfor %}
