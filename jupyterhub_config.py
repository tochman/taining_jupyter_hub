import os
import sys

from jupyterhub.spawner import SimpleLocalProcessSpawner

# Ensure that the directory containing custom_authenticator.py is in the Python path
sys.path.insert(0, os.path.abspath('/srv/jupyterhub'))

from custom_authenticator import CustomAuthenticator

c = get_config()

# Set log level for debugging
c.JupyterHub.log_level = 'DEBUG'

# Determine the environment (production or local)
env = os.environ.get('ENV', 'local')

# Set the database URL based on the environment
if env == 'production':
    db_url = os.environ.get('DATABASE_URL', 'postgresql://jupyterhub:jupyter_2024@prod-host/jupyterhub_db')
else:
    db_url = 'postgresql://jupyterhub:jupyter_2024@host.docker.internal/jupyterhub_db'

# Apply the db_url to both JupyterHub and CustomAuthenticator
c.JupyterHub.db_url = db_url
c.CustomAuthenticator.db_url = db_url

# Set the authenticator class to your custom one
c.JupyterHub.authenticator_class = CustomAuthenticator

# Use SimpleLocalProcessSpawner
c.JupyterHub.spawner_class = SimpleLocalProcessSpawner


# Define the admin user (must be a system user)
c.Authenticator.admin_users = {'admin'}
c.Authenticator.allow_all = True

# Other configurations
c.JupyterHub.bind_url = 'http://:8000'
c.Spawner.default_url = '/lab'
c.Spawner.args = ['--allow-root']
c.Spawner.start_timeout = 60  # increase as needed
c.Spawner.http_timeout = 60

c.NotebookApp.default_kernel_name = 'deno'

# Logging
print(f"Environment: {env}")
print(f"Database URL: {db_url}")

auth = CustomAuthenticator()
auth.set_admin_password(password='admin')
