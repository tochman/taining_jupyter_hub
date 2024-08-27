import os
import sys
import shutil
from jupyterhub.spawner import SimpleLocalProcessSpawner

# Ensure that the directory containing custom_authenticator.py is in the Python path
sys.path.insert(0, os.path.abspath('/srv/jupyterhub'))
from custom_authenticator import CustomAuthenticator

class CustomSpawner(SimpleLocalProcessSpawner):
    def start(self):
        username = self.user.name
        home_dir = os.path.join("/srv/jupyterhub/home", username)
        shared_dir = "/srv/data/langchain_basics"
        user_link = os.path.join(home_dir, "langchain_basics")

        # Ensure the user home directory exists
        if not os.path.exists(home_dir):
            os.makedirs(home_dir)

        # Copy the shared folder to the user's directory
        if not os.path.exists(user_link):
            shutil.copytree(shared_dir, user_link)
            print(f"Copied shared folder for {username} to {user_link}")

        return super().start()

    def start(self):
        username = self.user.name
        home_dir = os.path.join("/srv/jupyterhub/home", username)
        shared_dir = "/srv/data/langchain_basics"
        user_dir = os.path.join(home_dir, "langchain_basics")

        # Ensure the user home directory exists
        if not os.path.exists(home_dir):
            os.makedirs(home_dir)

        # Copy the shared folder to the user's directory if it doesn't already exist
        if not os.path.exists(user_dir):
            shutil.copytree(shared_dir, user_dir)
            print(f"Copied {shared_dir} to {user_dir} for user {username}")

        return super().start()

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

# Use the custom spawner
c.JupyterHub.spawner_class = CustomSpawner

# Define the admin user (must be a system user)
c.Authenticator.admin_users = {'admin'}
c.Authenticator.allow_all = True

# Other configurations
if env == 'production':
    c.JupyterHub.bind_url = 'http://0.0.0.0:8080'
else:
    c.JupyterHub.bind_url = 'http://:8000'
c.Spawner.default_url = '/lab'
c.Spawner.args = ['--allow-root']
c.Spawner.start_timeout = 60
c.Spawner.http_timeout = 60
c.Spawner.environment = {'OPENAI_API_KEY': os.getenv('OPENAI_API_KEY')}
c.Spawner.notebook_dir = '/srv/jupyterhub/home/{username}'
c.NotebookApp.default_kernel_name = 'deno'

# Logging
print(f"Environment: {env}")
print(f"Database URL: {db_url}")

auth = CustomAuthenticator()
auth.set_admin_password(password='admin')
