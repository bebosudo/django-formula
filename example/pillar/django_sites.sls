# le_dir: /etc/letsencrypt                      # Default: '/etc/letsencrypt'
# le_oldest_cert_threshold: 10                  # When executing the highstate normally, if you set up the pillar for
                                                # the letsencrypt formula *pointing to the production server*, it will
                                                # request a new certificate each time, which could make you hit the
                                                # rate limit and crash the salt states execution.
                                                # This switch disable the letsencrypt state if the oldest certificate in
                                                # (le_dir)/live/*/fullchain.pem has less that this number of days.
                                                # Default: 10 (days).


django_sites:
  - name: poll
    git_address: https://github.com/Chive/django-poll-app.git
    # branch: master                            # Default: master.
    # rev: HEAD                                 # Default: HEAD.

    # url: example.com                          # Either an IP or a domain (such as 'example.com'); do not include slashes.
                                                # Default: public IP, from 'curl icanhazip.com'; make sure your firewall is
                                                # open to common http ports (80 and 443), and the domain points to your IP.
    http_port: 8000                             # Alternative port for plain http. Default: 80.
    user_name: shifu                            # Name of user under which run the app.
    install_dir: /var/www/poll                  # Make sure the user chosen is able to write in the parent dir,
                                                # or write a state in order to let it do so.

    # --------------------------------------------------------------------------------------------

    python_exe: python3.6                       # The name of the python exec. Make sure that pip is available;
                                                # test it with 'python_exe -m pip'. Default: 'python'
    # virtualenv_dir: /var/www/poll/.venv       # If provided, use an absolute path; default: '(install_dir)/.venv'.

    # requirements_file: requirements.txt       # Relative path in the repo; make sure it contains at least django.
                                                # and gunicorn, and also psycopg2 if you set up postgres below.
                                                # If not set, no python packages are installed in the venv.
    pip_packages:
      - Django==1.8                             # A list of packages to be manually installed, separately from the
      - gunicorn                                # requirements file; make sure gunicorn is present in the venv.
      - psycopg2-binary==2.7.5                  # Default: [].

    # setup_script: setup_params.py -123        # Relative path in the repo to an optional setup script to be executed
                                                # after migrations. Make sure it's idempotent.
    static_subdirs: ["/media", "/static"]       # List of relative paths to directories to be created in the repo.
                                                # Remember the trailing slash. Default: do not create dirs.
    collectstatic: True                         # STATIC_ROOT is required in the site's settings file. Add the STATIC_ROOT dir
                                                # to the 'static_subdirs' list above in order to let it be created.
    settings_dir: mysite                        # Name of the directory containing the site's settings.

    # --------------------------------------------------------------------------------------------

    {% set site1_db_name, site1_db_user_name, site1_db_user_pswd = "polls_db", "shifu_db1", "asdfasdf" %}
    # enable_postgres: True                     # Default: True.
    db_name: "{{ site1_db_name }}"              # Default: the site name.
    db_user_name: "{{ site1_db_user_name }}"    # Default: user_name; make sure the users defined in your django sites are different,
                                                # or you could get a name collision on the IDs of the states creating the db users.
    db_user_pswd: "{{ site1_db_user_pswd }}"
    # lc_ctype: "en_US.UTF-8"                   # Default: 'en_US.UTF-8'
    # lc_collate: "en_US.UTF-8"                 # Default: 'en_US.UTF-8'

    # --------------------------------------------------------------------------------------------

    # The following options work only when a domain is passed as url above, since Let’s Encrypt
    # SSL certificates are tied to domains, not IPs.
    # https://community.letsencrypt.org/t/certificate-for-public-ip-without-domain-name/6082

    # request_https: True                       # Request a SSL certificate (https) for the domain,
                                                # using Let's Encrypt; default: True.
    # request_www: True                         # Request a SSL certificate (https) for 'www.';  default: True.
    # request_mail: False                       # Request a SSL certificate (https) for 'mail.'; default: False.
    # force_https: True                         # Force http -> https; default: True.
    # redirect_www_domain: True                 # www. -> .;     default: True.
    # redirect_mail_domain: False               # mail.:80/443 -> .; default: False.
    # mail_subdomain: mx                        # Default: 'mail'.

    # --------------------------------------------------------------------------------------------

    users:
    - name: admin
      password: change@me
      is_superuser: True
      email: change@me                          # The email is required when creating a superuser.
    - name: poll_user01
      password: password123


    # --------------------------------------------------------------------------------------------

    # settings_source_file: salt://example.j2   # The path to a settings file to use. This 'site' dictionary will
                                                # be available as a Jinja context, so you can apply jinja magic
                                                # in your own settings file by specifing options in the 'settings'
                                                # dictionary below.
    # settings_source_enable_jinja: True        # Enable the Jinja substitution in the settings source file provided.
                                                # Default: True.

    settings:
      imports: ["os", "django"]                 # List of libraries to be imported in the settings file.
                                                # Default: ["os"]
      # middlewares: []                         # Middlewares other than the "classic" ones. Default: [].

      installed_apps: ["polls"]                 # Installed apps other than the "classic" ones. Default: [].

      # WSGI_APPLICATION: 'mysite.wsgi.application'

      # SECRET_KEY: "s3cr37"                    # Default: each time a random string of length 100.
      # DEBUG: False                            # Never enable debug in production! Leave it to False or do not set it.
      # ALLOWED_HOSTS: [".example.com", ]       # Default: url of the site and all its subdomains.


      ROOT_URLCONF: 'mysite.urls'
      # FORM_RENDERER: "django.forms.renderers.TemplatesSetting"

      TEMPLATES:
        # - BACKEND: '"django.template.backends.jinja2.Jinja2"'
        #   DIRS: ['"mysite/widgets"', '"{}/forms/jinja2".format(django.__path__[0])']
        #   APP_DIRS: True
        #   OPTIONS:
        #     environment: "_settings.jinja2.environment"
        #     context_processors: ["django.template.context_processors.debug",]

        - BACKEND: '"django.template.backends.django.DjangoTemplates"'
          DIRS: []
          APP_DIRS: True
          OPTIONS:
            context_processors:
              - "django.template.context_processors.debug"
              - "django.template.context_processors.request"
              - "django.contrib.auth.context_processors.auth"
              - "django.contrib.messages.context_processors.messages"

      DATABASES:
        default:
          ENGINE: '"django.db.backends.postgresql_psycopg2"'
          NAME: '"{{ site1_db_name }}"'
          USER: '"{{ site1_db_user_name }}"'
          PASSWORD: '"{{ site1_db_user_pswd }}"'
          HOST: '"localhost"'
          PORT: '""'

      AUTH_PASSWORD_VALIDATORS:
        - NAME: "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
        - NAME: "django.contrib.auth.password_validation.MinimumLengthValidator"
        - NAME: "django.contrib.auth.password_validation.CommonPasswordValidator"
        - NAME: "django.contrib.auth.password_validation.NumericPasswordValidator"

      LANGUAGE_CODE: "en-us"
      USE_I18N: True
      USE_L10N: True
      USE_TZ: True
      TIME_ZONE: "Etc/UTC"

      STATICFILES_DIRS: []
      STATIC_URL: "/static/"
      STATIC_ROOT: "static/"                    # Relative path inside the repo dir where to collect static files.

      OTHER_SETTINGS:                           # Other key-values variables, to update 'globals()'.
        ADMINS:
          - ['Your Name', 'your_email@example.com']

        # REST_FRAMEWORK:
        #   DEFAULT_PERMISSION_CLASSES:
        #     - "rest_framework.permissions.IsAuthenticated"



  # ============================================================================================ #


  - name: django-ex
    http_port: 8001
    install_dir: /var/www/django-ex
    git_address: https://github.com/sclorg/django-ex.git
    user_name: crane

    python_exe: python3.6
    requirements_file: requirements.txt
    collectstatic: True
    static_subdirs: ["media/", "static/"]

    wsgi_path: "wsgi"                           # This project placed the wsgi module in the root of the project.
    settings_dir: project

    enable_postgres: False

    users:
    - name: admin
      password: change@me
      is_superuser: True
      email: change@me
    - name: user02
      password: asdfhff

