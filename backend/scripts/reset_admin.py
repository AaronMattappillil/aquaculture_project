import asyncio
import os
import sys
import getpass
from bson import ObjectId

# Add parent directory to path to allow imports from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/..")

from app.db.mongo import users_collection
from app.core.security import hash_password

async def reset_admin():
    print("--- Aquaculture Admin Password Reset Tool ---")
    
    # 1. Fetch Admin
    admin_user = await users_collection().find_one({"username": "admin"})
    if not admin_user:
        print("Error: 'admin' user not found in database.")
        return

    # 2. Get New Password
    new_password = getpass.getpass("Enter new password for 'admin': ")
    confirm_password = getpass.getpass("Confirm new password: ")
    
    if new_password != confirm_password:
        print("Error: Passwords do not match.")
        return
        
    if len(new_password) < 8:
        print("Error: Password must be at least 8 characters.")
        return

    # 3. Hash and Update
    print("Hashing password using modern SHA-256 + Bcrypt standard...")
    new_hash = hash_password(new_password)
    
    result = await users_collection().update_one(
        {"username": "admin"},
        {"$set": {"password_hash": new_hash}}
    )
    
    if result.modified_count > 0:
        print("Success: Admin password has been updated and modernized.")
    else:
        print("Notice: Password hash was already up to date or update failed.")

if __name__ == "__main__":
    asyncio.run(reset_admin())
