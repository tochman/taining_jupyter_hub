# Start with an official Python runtime as a parent image
FROM python:3.10-slim

# Install necessary system packages
RUN apt-get update && apt-get install -y \
    npm \
    nodejs \
    sudo \
    adduser \
    libpq-dev \
    gcc \
    curl \
    unzip \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create the jupyterhub user
RUN adduser --disabled-password --gecos "" jupyterhub

# Switch to the jupyterhub user
USER jupyterhub

# Install Deno for the jupyterhub user
RUN curl -fsSL https://deno.land/install.sh | sh

# Set environment variables for Deno
ENV DENO_INSTALL="/home/jupyterhub/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

# Install the Deno Jupyter kernel as the jupyterhub user
RUN deno jupyter --install

# Switch back to root user to move the kernel to the global directory
USER root


# Install JupyterHub, notebook, and psycopg2 for PostgreSQL as root
RUN pip install jupyterhub notebook psycopg2-binary bcrypt

# Install configurable-http-proxy for JupyterHub
RUN npm install -g configurable-http-proxy

# Copy all necessary files
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY custom_authenticator.py /srv/jupyterhub/custom_authenticator.py
COPY create_user.sh /srv/jupyterhub/create_user.sh
COPY create_admin.py /srv/jupyterhub/create_admin.py
COPY startup.sh /srv/jupyterhub/startup.sh

# Set correct permissions
RUN chmod +x /srv/jupyterhub/create_user.sh /srv/jupyterhub/startup.sh

# Set the working directory
WORKDIR /srv/jupyterhub
# Move the Deno kernel to the global Jupyter kernels directory
RUN mv /home/jupyterhub/.local/share/jupyter/kernels/deno /usr/local/share/jupyter/kernels/

# Switch back to jupyterhub user to run the JupyterHub service
# USER jupyterhub

# Set the default command to start JupyterHub
CMD ["/srv/jupyterhub/startup.sh"]
