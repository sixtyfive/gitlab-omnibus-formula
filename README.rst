======================
gitlab-omnibus-formula
======================

.. image:: https://travis-ci.org/corux/gitlab-omnibus-formula.svg?branch=master
    :target: https://travis-ci.org/corux/gitlab-omnibus-formula

Installs the GitLab CE server from the Omnibus package.

Available states
================

.. contents::
    :local:

``gitlab-omnibus``
------------------

Installs the GitLab CE server from the Omnibus packages.

``gitlab-omnibus.gitsshd``
--------------------------

Sets up a SSH Server configuration, which allows only the git user to connect.

There is a `selinux` configuration parameter (default: `true`) that causes a dependency on the selinux formula specified in `gitshelf.yml`.

``gitlab-omnibus.runner``
-------------------------

Setup the GitLab CI runner.
