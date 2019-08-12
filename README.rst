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

``gitlab-omnibus.gitsshd-noselinux``
------------------------------------

The same as above, but without requiring the `selinux` formula.

``gitlab-omnibus.runner``
-------------------------

Setup the GitLab CI runner.
