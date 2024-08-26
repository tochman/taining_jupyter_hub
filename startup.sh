#!/bin/bash

# Check if the admin user exists
python <<EOF
from custom_authenticator import CustomAuthenticator
auth = CustomAuthenticator()

session = auth.get_session()
user = session.query(User).filter_by(name='admin').first()

if not user:
    # Create the admin user with a predefined password
    auth.add_user('admin', 'admin')
else:
    # Optionally reset the admin password on each startup
    auth.set_password('admin', 'admin')
EOF

# Start JupyterHub
jupyterhub -f /srv/jupyterhub/jupyterhub_config.py
