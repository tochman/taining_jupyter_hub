from jupyterhub.auth import Authenticator
from jupyterhub import orm
from traitlets import Unicode
import bcrypt
from sqlalchemy import create_engine, Column, String
from sqlalchemy.orm import sessionmaker
import os

# Extending the existing User model to add a password attribute
class ExtendedUser(orm.User):
    password = Column(String(128))

class CustomAuthenticator(Authenticator):
    db_url = Unicode(config=True)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Set the db_url based on environment
        env = os.environ.get('ENV', 'local')
        
        if env == 'production':
            self.db_url = os.environ.get('DATABASE_URL', 'postgresql://jupyterhub:jupyter_2024@prod-host/jupyterhub_db')
        else:
            self.db_url = 'postgresql://jupyterhub:jupyter_2024@host.docker.internal/jupyterhub_db'

        if not self.db_url:
            raise ValueError("db_url must be provided")

        self.engine = create_engine(self.db_url)
        self.Session = sessionmaker(bind=self.engine)

    def get_session(self):
        """Create a new session for database transactions."""
        return self.Session()

    def ensure_password_column(self):
        """Ensure the password column exists in the users table."""
        # Ensure the column exists at runtime
        pass

    async def authenticate(self, handler, data):
        username = data['username']
        password = data['password']

        session = self.get_session()
        try:
            user = session.query(ExtendedUser).filter_by(name=str(username)).first()

            if user and user.password:
                if bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
                    return username
        finally:
            session.close()
        
        return None

    def add_user(self, user, password=None):
        username = user.name  # Ensure this is correctly passed as a string

        # Set default password if none is provided
        if not password:
            password = "password"  # Default password
            self.log.info(f"Setting default password for user: {username}")

        session = self.get_session()
        try:
            # Ensure the password column exists
            self.ensure_password_column()

            # Check if the user already exists
            existing_user = session.query(ExtendedUser).filter_by(name=str(username)).first()

            if existing_user:
                self.log.info(f"User {username} already exists. Updating password.")
                # Update password if a new one is provided or if we are setting a default password
                hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                existing_user.password = hashed_password
                session.commit()
                return existing_user
            else:
                # Create a new user with the provided or default password
                hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                new_user = ExtendedUser(name=username, password=hashed_password)
                session.add(new_user)
                session.commit()
                return new_user
        finally:
            session.close()

    def set_password(self, user, password):
        session = self.get_session()
        try:
            user.password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            session.commit()
        finally:
            session.close()


    def set_admin_password(self, username='admin', password='your_password_here'):
        session = self.get_session()
        user = session.query(ExtendedUser).filter_by(name=username).first()

        if user:
            user.password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            session.commit()
            print(f"Password set successfully for user {username}")
        else:
            print(f"User {username} not found")
        session.close()