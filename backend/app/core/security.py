import os
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import jwt
import bcrypt

from app.core.config import get_settings

_settings = get_settings()


def create_access_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta is None:
        expires_delta = timedelta(minutes=_settings.jwt_access_token_expires_minutes)
    
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode: dict[str, Any] = {
        "sub": str(subject),
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "nbf": datetime.now(timezone.utc)
    }
    
    encoded_jwt = jwt.encode(
        to_encode, 
        _settings.jwt_secret_key, 
        algorithm=_settings.jwt_algorithm
    )
    return encoded_jwt


def get_password_hash(password: str) -> bytes:
    """Pre-hash with SHA-256 to handle bcrypt's 72-byte limit."""
    return hashlib.sha256(password.encode()).digest()


def verify_password(plain: str, hashed: str) -> bool:
    """
    Verifies a password against a hash using a hybrid strategy:
    1. Modern: SHA-256 pre-hashing + bcrypt (handles >72 chars)
    2. Legacy: Direct bcrypt check (fallback for older accounts)
    """
    try:
        if not plain or not hashed:
            return False
            
        # 1. Attempt Modern Verification (SHA-256 pre-hashing)
        # This is our current standard that handles passwords > 72 bytes.
        plain_hash_modern = hashlib.sha256(plain.encode()).digest()
        if bcrypt.checkpw(plain_hash_modern, hashed.encode()):
            return True

        # 2. Attempt Legacy Verification (Direct bcrypt)
        # Fallback for accounts created before the SHA-256 pre-hash update.
        # Note: Standard bcrypt will truncate inputs > 72 bytes internally.
        if bcrypt.checkpw(plain.encode(), hashed.encode()):
            return True
            
        return False
    except Exception:
        # Avoid crashing on malformed hashes or encoding errors
        return False


def hash_password(password: str) -> str:
    """Hashes a password using the current modern standard (SHA-256 + bcrypt)."""
    # 1. Pre-hash with SHA-256 to ensure we handle long passwords correctly
    password_hash = hashlib.sha256(password.encode()).digest()
    
    # 2. Hash with bcrypt (generates its own salt)
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_hash, salt)
    
    return hashed.decode()

