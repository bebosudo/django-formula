Install python and pip:
  pkg.installed:
    - name: python36-setuptools
  cmd.run:
    - name: easy_install-3.6 pip
    - unless: python3.6 -m pip --version
