{% from "gitlab-omnibus/map.jinja" import gitlab with context %}
{% from "selinux/map.jinja" import selinux with context %}

gitsshd:
  file.managed:
    - name: /etc/systemd/system/gitsshd.service
    - source: salt://gitlab-omnibus/files/gitsshd.service

  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: gitsshd

  service.running:
    - name: gitsshd
    - enable: True
    - require:
      - file: gitsshd
      - file: gitsshd-config

gitsshd-config:
  file.managed:
    - name: /etc/ssh/gitsshd_config
    - template: jinja
    - source: salt://gitlab-omnibus/files/gitsshd_config
    - user: root
    - group: root
    - mode: 600
    - defaults:
        config: {{ gitlab.gitsshd|json }}

{% if selinux.enabled %}
include:
  - selinux

gitsshd-selinux-pid:
  cmd.run:
    - name: semanage fcontext -a -t sshd_var_run_t '{{ gitlab.gitsshd.pidfile }}'
    - unless: semanage fcontext --list | grep '{{ gitlab.gitsshd.pidfile }}' | grep sshd_var_run_t
    - require:
      - pkg: policycoreutils-python
    - require_in:
      - service: gitsshd

gitsshd-selinux-port:
  cmd.run:
    - name: semanage port -a -t ssh_port_t -p tcp {{ gitlab.gitsshd.port }}
    - unless: semanage port --list | grep ssh_port_t | grep {{ gitlab.gitsshd.port }}
    - require:
      - pkg: policycoreutils-python
    - require_in:
      - service: gitsshd

gitsshd-selinux-restorecon:
  module.wait:
    - name: file.restorecon
    - path: {{ gitlab.gitsshd.pidfile }}
    - watch:
      - cmd: gitsshd-selinux-pid
{% endif %}
