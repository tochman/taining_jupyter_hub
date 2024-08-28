#!/bin/bash

# Function to check the database connection
check_db_connection() {
    python <<EOF
import psycopg2
import os

try:
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    print("Database connection successful!")
    conn.close()
except Exception as e:
    print(f"Database connection failed: {e}")
    exit(1)
EOF
}

# Function to upgrade the database schema
upgrade_db() {
    jupyterhub upgrade-db
}

# Function to manually initialize the database schema if necessary
initialize_db_schema() {
    python <<EOF
from custom_authenticator import CustomAuthenticator, orm
from sqlalchemy import create_engine
import os

# Initialize custom authenticator and database session
auth = CustomAuthenticator()
engine = create_engine(auth.db_url)
orm.Base.metadata.create_all(engine)

session = auth.get_session()
user = session.query(orm.User).filter_by(name='admin').first()

if not user:
    # Create the admin user with a predefined password
    auth.add_user('admin', 'admin')
else:
    # Optionally reset the admin password on each startup
    auth.set_password(user, 'admin')

session.commit()
session.close()
EOF
}

# Function to create the users table manually if it doesn't exist
create_users_table() {
    python <<EOF
import psycopg2
import os

conn = psycopg2.connect(os.getenv('DATABASE_URL'))
cur = conn.cursor()

# Create the users table manually if it doesn't exist
cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) UNIQUE NOT NULL,
        admin BOOLEAN DEFAULT FALSE,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_activity TIMESTAMP,
        cookie_id VARCHAR(100),
        state BYTEA,
        encrypted_auth_state BYTEA,
        password VARCHAR(128)
    );
""")
conn.commit()
cur.close()
conn.close()
EOF
}

# Step 1: Check the database connection
check_db_connection

# Step 2: Upgrade the database schema
upgrade_db

# Step 3: Initialize the database schema if necessary
initialize_db_schema

# Step 4: Manually create the users table if it doesn't exist
create_users_table

# Step 5: Start JupyterHub
exec jupyterhub -f /srv/jupyterhub/jupyterhub_config.py
