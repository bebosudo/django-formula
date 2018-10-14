install some common packages:
  pkg.installed:
    - pkgs:
      - nano
      - python36-setuptools
      - nmap-ncat
      - bash-completion
      - bind-utils
      - tree

delete unneeded packages:
  pkg.removed:
    - pkgs:
      - rpcbind


# TODO: Disable selinux for the moment until we don't fix it in states.
setenforce Permissive:
  cmd.run: []


{% for site in salt["pillar.get"]("django_sites", []) %}
Create user {{ site.user_name }} for site {{ site.name }}:
  user.present:
    - name: {{ site.user_name }}
{% endfor %}
