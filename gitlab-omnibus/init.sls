{% from "gitlab-omnibus/map.jinja" import gitlab with context %}

include:
  - .repo

gitlab-deps:
  pkg.installed:
    - pkgs: {{ gitlab.dependencies|json }}

gitlab-repo:
  pkgrepo.managed:
    - humanname: Gitlab CE Repository
    {%- if grains.os_family == 'Debian' %}
    - name: deb https://packages.gitlab.com/gitlab/gitlab-ce/{{ grains.os|lower }} {{ grains.oscodename }} main
    - file: /etc/apt/sources.list.d/gitlab_ce.list
    - key_url: {{ gitlab.gpgkey_url }}
    {%- elif grains.os_family == 'RedHat' %}
    - baseurl: https://packages.gitlab.com/gitlab/gitlab-ce/el/$releasever/$basearch
    - gpgcheck: 0
    - gpgkey: {{ gitlab.gpgkey_url }}
    - require:
      - cmd: gitlab-repo-key
    {%- endif %}

{% if 'secrets' in gitlab %}
gitlab-secrets:
  file.serialize:
    - name: {{ gitlab.secrets_file }}
    - dataset_pillar: gitlab:secrets
    - formatter: json
    - makedirs: True
    - mode: 0600
    - merge_if_exists: True
    - require:
      - pkg: gitlab
    - require_in:
      - service: gitlab
{% endif %}

gitlab:
  pkg.installed:
    - name: gitlab-ce
    - require:
      - pkgrepo: gitlab-repo
      - pkg: gitlab-deps

  service.running:
    - name: gitlab-runsvdir
    - require:
      - pkg: gitlab
      - cmd: gitlab-upgrade
      - cmd: gitlab-reconfigure

gitlab-url:
  file.replace:
    - name: {{ gitlab.config_file }}
    - pattern: ^#?\s*external_url\s.*$
    - repl: external_url {{ gitlab.url|yaml_dquote }}
    - append_if_not_found: True
    - require:
      - pkg: gitlab

{% if 'registry_external_url' in gitlab %}
docker-registry-url:
  file.replace:
    - name: {{ gitlab.config_file }}
    - pattern: ^#?\s*registry_external_url\s.*$
    - repl: registry_external_url {{ gitlab.registry_external_url|yaml_dquote }}
    - append_if_not_found: True
    - require:
      - pkg: gitlab
{% endif %}

{% if 'mattermost_url' in gitlab %}
mattermost-url:
  file.replace:
    - name: {{ gitlab.config_file }}
    - pattern: ^#?\s*mattermost_external_url\s.*$
    - repl: mattermost_external_url {{ gitlab.mattermost_url|yaml_dquote }}
    - append_if_not_found: True
    - require:
      - pkg: gitlab
    - onchanges_in:
      - cmd: gitlab-reconfigure

{% endif %}

{% if gitlab.pki %}
{% if 'certificate' in gitlab.pki %}
gitlab-ssl-cert:
  file.managed:
    - name: {{ gitlab.pki.certificate_file }}
    - mode: 600
    - contents: |-
        {{ gitlab.pki.certificate | indent(8) }}
    - require:
      - pkg: gitlab
{% endif %}

{% if 'key' in gitlab.pki %}
gitlab-ssl-key:
  file.managed:
    - name: {{ gitlab.pki.key_file }}
    - mode: 600
    - contents: |-
        {{ gitlab.pki.key | indent(8) }}
    - require:
      - pkg: gitlab
{% endif %}
{% endif %}

gitlab-config:
  file.blockreplace:
    - name: {{ gitlab.config_file }}
    - prepend_if_not_found: True

{% for section, val in gitlab.config|dictsort %}
{% for key, value in val|dictsort %}
gitlab-config-{{ section }}-{{ key }}:
  file.accumulated:
    - name: gitlab-config-accumulator
    - filename: {{ gitlab.config_file }}
    - text: |
        {{ section }}['{{ key }}'] = {% if value is string -%}
        {{ value|indent(8) }}
        {%- else -%}
        {{ value|yaml_encode }}
        {%- endif %}
    - require_in:
      - file: gitlab-config
{% endfor %}
{% endfor %}

gitlab-upgrade:
  cmd.run:
    - name: gitlab-ctl upgrade
    - onchanges:
      - pkg: gitlab

# gitlab does not initialize the service, if a docker-environment is detected
gitlab-reconfigure:
  cmd.run:
    - name: rm -f /.dockerenv ; gitlab-ctl reconfigure
    - require:
      - pkg: gitlab
    - onchanges:
      - file: gitlab-config
      - file: gitlab-url
