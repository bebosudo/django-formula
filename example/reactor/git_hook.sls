{% set secret_key = data.get('headers', {}).get('X-Gitlab-Token') %}          # Gitlab
{# {% set secret_key = data.get('headers', {}).get('X-Hub-Signature') %} #}   # Github

# Create a random token (avoid chars like $%+'"` because they can be wrongly converted or should be escaped):
#   < /dev/urandom tr -dc 'A-Za-z0-9*,./:<=>?@[]^_{|}~' | head -c 100
{% if secret_key == 'change_super_secret_key_here!' %}
highstate_run:
  local.state.highstate:
    - tgt: "*"
{% endif %}

