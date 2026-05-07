"""
Database Configuration and Models
Handles PostgreSQL connection and vote storage
"""

import os
import time
from sqlalchemy import create_engine, Column, Integer, String, DateTime, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Get database credentials from environment variables
DB_USER = os.getenv('DB_USER', 'admin')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'admin123')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'polls')

# Construct PostgreSQL connection string
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Create SQLAlchemy engine with connection pool settings
engine = None
Session = None

def init_db():
    """
    Initialize database connection with retry mechanism.
    Retries every 2 seconds for up to 30 seconds if PostgreSQL is starting.
    """
    global engine, Session
    
    max_retries = 15
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            # Create engine with pool settings
            engine = create_engine(
                DATABASE_URL,
                pool_pre_ping=True,  # Test connections before using them
                pool_size=10,
                max_overflow=20,
                echo=False
            )
            
            # Test the connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            
            # Create session factory
            Session = sessionmaker(bind=engine)
            
            # Create all tables
            Base.metadata.create_all(engine)
            
            print("✓ Database connection successful!")
            return True
            
        except Exception as e:
            retry_count += 1
            if retry_count < max_retries:
                print(f"⏳ Waiting for PostgreSQL... ({retry_count}/{max_retries})")
                time.sleep(2)
            else:
                print(f"✗ Failed to connect to database after {max_retries} retries")
                raise e
    
    return False

# SQLAlchemy Base class for ORM models
Base = declarative_base()

class Vote(Base):
    """
    Vote Model - Represents a single user vote
    
    Attributes:
        id: Unique vote identifier (Primary Key)
        option: Vote choice ('yes' or 'no')
        created_at: Timestamp when vote was cast
    """
    __tablename__ = 'votes'
    
    id = Column(Integer, primary_key=True)
    option = Column(String(10), nullable=False)  # 'yes' or 'no'
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    def __repr__(self):
        return f"<Vote(id={self.id}, option='{self.option}', created_at='{self.created_at}')>"

def get_session():
    """Get a new database session"""
    return Session()

def add_vote(option):
    """
    Add a new vote to the database
    
    Args:
        option (str): Vote option ('yes' or 'no')
    
    Returns:
        bool: True if vote was added successfully
    """
    session = get_session()
    try:
        new_vote = Vote(option=option.lower())
        session.add(new_vote)
        session.commit()
        return True
    except Exception as e:
        session.rollback()
        print(f"Error adding vote: {e}")
        return False
    finally:
        session.close()

def get_results():
    """
    Retrieve voting results
    
    Returns:
        dict: Contains yes_count, no_count, total_votes, yes_percentage, no_percentage
    """
    session = get_session()
    try:
        # Count votes for each option
        yes_votes = session.query(Vote).filter(Vote.option == 'yes').count()
        no_votes = session.query(Vote).filter(Vote.option == 'no').count()
        total_votes = yes_votes + no_votes
        
        # Calculate percentages
        yes_percentage = round((yes_votes / total_votes * 100), 2) if total_votes > 0 else 0
        no_percentage = round((no_votes / total_votes * 100), 2) if total_votes > 0 else 0
        
        return {
            'yes_count': yes_votes,
            'no_count': no_votes,
            'total_votes': total_votes,
            'yes_percentage': yes_percentage,
            'no_percentage': no_percentage
        }
    except Exception as e:
        print(f"Error fetching results: {e}")
        return {
            'yes_count': 0,
            'no_count': 0,
            'total_votes': 0,
            'yes_percentage': 0,
            'no_percentage': 0
        }
    finally:
        session.close()
