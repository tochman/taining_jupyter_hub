from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from jupyterhub import orm
import bcrypt

db_url = 'postgresql://jupyterhub:jupyter_2024@host.docker.internal/jupyterhub_db'
engine = create_engine(db_url)
Session = sessionmaker(bind=engine)
session = Session()

user = session.query(orm.User).filter_by(name='admin').first()
if user:
    user.password = bcrypt.hashpw('your_password_here'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    session.commit()
    print("Password set successfully for user admin")
else:
    print("User admin not found")
    
session.close()
