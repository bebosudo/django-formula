base:
  '*':
    - common
    - letsencrypt_setup
    - nginx_setup
    - postgres                # Postgres formula.
    - install_python          # Setup python3.6 and pip.
    - django.full             # Django formula.
