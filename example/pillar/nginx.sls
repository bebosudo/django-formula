{% import_yaml "django_sites.sls" as django_sites %}

nginx:
  ng:
    service:
      enable: True

    servers:
      managed:
        {% for site in django_sites.django_sites %}
        {% set url = site.get("url", salt.cmd.run("curl -s icanhazip.com")) %}

        {% set server_names = url %}
        {% if site.get("request_www", True) and not url | is_ip %} {% set server_names = server_names + " www." + url %} {% endif %}
        {% if site.get("request_mail", False) and not url | is_ip %}{% set server_names = server_names + " " + site.get("mail_subdomain", "mail") + "." + url %}{% endif %}

        {% set favicon = [{"access_log": "off"}, {"log_not_found": "off"}] %}
        {% set app_server = [{"proxy_set_header": "Host $http_host"}, {"proxy_set_header": "X-Real-IP $remote_addr"}, {"proxy_set_header": "X-Forwarded-For $proxy_add_x_forwarded_for"}, {"proxy_set_header": "X-Forwarded-Proto $scheme"}, {"proxy_pass": "http://unix:" + site.install_dir + "/" + site.name + ".sock"}] %}
        {% set cert, cert_key = django_sites.get("le_dir", "/etc/letsencrypt") + "/live/" + url + "/fullchain.pem", django_sites.get("le_dir", "/etc/letsencrypt") + "/live/" + url + "/privkey.pem" %}
        {% set hsts = 'Strict-Transport-Security "max-age=31536000" always' %}

        {{ site.name }}.conf:
          enabled: True
          config:

            # --------------------------- HTTP only ---------------------------
            {% if url | is_ip or not site.get("request_https", True) %}
            - server:
              # Do not use http/2.0 with normal http, it makes nginx return strange blobs.
              - listen: {{ site.get("http_port", "80") }}
              - server_name: {{ server_names }}

              - location /favicon.ico: {{ favicon }}
              {% for endpoint in site.static_subdirs %}
              - location {{ endpoint }}:
                - root: {{ site.install_dir }}
              {% endfor %}
              - location /: {{ app_server }}
            {% endif %}

            # ---------------------------   HTTPS   ---------------------------
            {% if not url | is_ip and site.get("request_https", True) %}
            - server:
              - listen: {{ site.get("http_port", "80") }}
              - server_name: {{ server_names }}

              {% if site.get("force_https", True) %}
              - return: 301 https://$server_name$request_uri

              {% else %}
              - location /favicon.ico: {{ favicon }}
              {% for endpoint in site.static_subdirs %}
              - location {{ endpoint }}:
                - root: {{ site.install_dir }}
              {% endfor %}
              - location /: {{ app_server }}
              {% endif %}

            {% if site.get("force_redirect_www_domain", True) %}
            - server:
              - listen: 443 ssl http2
              - server_name: www.{{ url }}
              - add_header: {{ hsts }}
              - ssl_certificate: {{ cert }}
              - ssl_certificate_key: {{ cert_key }}
              - return: 301 $scheme://{{ url }}$request_uri
            {% endif %}

            {% if site.get("force_redirect_mail_domain", False) %}
            - server:
              - listen: 443 ssl http2
              - server_name: {{ site.get("mail_subdomain", "mail") + "." + url }}
              - add_header: {{ hsts }}
              - ssl_certificate: {{ cert }}
              - ssl_certificate_key: {{ cert_key }}
              - return: 301 $scheme://{{ url }}$request_uri
            {% endif %}

            - server:
              - listen: 443 ssl http2
              {% if site.get("force_redirect_www_domain", True) %}
              - server_name: {{ url }}
              {% else %}
              - server_name: {{ server_names }}
              {% endif %}

                # Add Strict-Transport-Security to prevent man in the middle attacks
              - add_header: {{ hsts }}
              - ssl_certificate: {{ cert }}
              - ssl_certificate_key: {{ cert_key }}

              - location /favicon.ico: {{ favicon }}
              {% for endpoint in site.static_subdirs %}
              - location {{ endpoint }}:
                - root: {{ site.install_dir }}
              {% endfor %}
              - location /: {{ app_server }}

            {% endif %}
        {% endfor %}
