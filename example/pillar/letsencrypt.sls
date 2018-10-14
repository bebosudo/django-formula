{% import_yaml "django_sites.sls" as django_sites %}

{% set https_domains, mail_domains = [], [] %}
{% for site in django_sites.django_sites %}
  {% set url = site.get("url", salt.cmd.run("curl -s icanhazip.com")) %}
  {% if not url | is_ip and site.get("request_https", True) %}

    {{ https_domains.append(url) | default("", True) }}
    {% if site.get("request_www", True) %}
      {{ https_domains.append("www." + url) | default("", True) }}
    {% endif %}

    {% if site.get("request_mail", False) %}
      {{ mail_domains.append(site.get("mail_subdomain", "mail") + "." + url) | default("", True) }}
    {% endif %}

  {% endif %}
{% endfor %}


letsencrypt:
  use_package: true                             # Install using packages instead of git
  pkgs:                                         # A list of package/s to install. Check https://certbot.eff.org/all-instructions
    - python2-certbot-nginx                     # to find the correct name for the variant you want to use. Usually, you'll
                                                # need a single one, but you can also add other plugins here

  {% set webpath = "/var/lib/www" %}
  webroot-path: {{ webpath }}                   # Make sure webroot-path exists.
  le_oldest_cert_threshold: "{{ django_sites.get("le_oldest_cert_threshold", "10") }}"


  # Make sure to switch to the production server once you're ready with your tests,
  # because production certificates are rate-limited.
  config: |
    # server = https://acme-v01.api.letsencrypt.org/directory
    server = https://acme-staging.api.letsencrypt.org/directory
    email = your_email@example.com
    authenticator = nginx
    webroot-path = {{ webpath }}
    agree-tos = True
    renew-by-default = True

  config_dir:
    path: {{ django_sites.get("le_dir", "/etc/letsencrypt") }}
    user: root
    group: root
    mode: 755


  {% if https_domains %}
  domainsets:
    www: {{ https_domains }}

    {% if mail_domains %}
    mail: {{ mail_domains }}
    {% endif %}
  {% endif %}

