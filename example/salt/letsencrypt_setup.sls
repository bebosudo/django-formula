# This complex piece of code is needed to select the domains to request certificates.
# If there are none, we don't include the letsencrypt formula at all.
{% set https_domains, mail_domains = [], [] %}
{% for site in salt["pillar.get"]("django_sites", []) %}

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


# First of all, check whether any domain has to be requested, then check whether any certificate already exists
# or whether the oldest certificate is older than a given number of days. (https://stackoverflow.com/a/1401541/)
{% if (https_domains and
       (salt.cmd.run('bash -c "ls ' + salt["pillar.get"]("letsencrypt:config_dir:path") + '/live/*/fullchain.pem 2>/dev/null |wc -l"') == "0" or
        salt.cmd.run('bash -c "[ $(echo $(( ($(date +%s) - $(stat -L --format %Y $(ls -t ' + salt["pillar.get"]("letsencrypt:config_dir:path") + '/live/*/fullchain.pem |tail -1) ) ) ))) -gt $(( 60 * 60 * 24 * {})) ] && echo greater || echo less"'.format(salt["pillar.get"]("letsencrypt:le_oldest_cert_threshold", 10)) ) == "greater"
       )
      )
%}

include:
  - letsencrypt

Create the webroot-path directory where the challenge files are placed:
  file.directory:
    - name: {{ salt["pillar.get"]("letsencrypt:webroot-path") }}
    - require_in:
      - pkg: letsencrypt-client


Install nginx so that letsencrypt can conclude the setup:
  pkg.installed:
    - name: nginx

  service.running:
    - name: nginx
    - require:
      - pkg: Install nginx so that letsencrypt can conclude the setup
    - require_in:
      - pkg: letsencrypt-client

{% endif %}
