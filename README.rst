==============
django-formula
==============

| A SaltStack formula to configure and deploy multiple django websites.
| Tested on Centos 7.

A working example, using Postgres, NGINX, gunicorn and Let's Encrypt, is available in the `example directory <https://github.com/bebosudo/django-formula/tree/master/example/>`_.


**NOTE**

See the full `Salt Formulas installation and usage instructions <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:


``venv``
------------

Globally install ``virtualenv`` with pip, setup a python virtualenv for each site, and install packages if requested.


``settings``
------------

Build the ``settings.py`` file for each site, using the file provided or by "compiling" the settings parameters in the pillar.


``gunicorn``
------------

Configure systemd services for gunicorn, the WSGI server.


``git``
------------

Download the latest source files of each site from the git address provided (**note**: the content in the installation directory will be wiped each time).


``full``
------------

Apply all of the above states.


License
=======

| This project is licensed under the Apache License, version 2.0.
| For the full license, refer to the LICENSE file in the root directory of this project.

::

    Copyright 2018 Alberto Chiusole

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
