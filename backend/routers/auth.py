from fastapi import APIRouter, HTTPException, Depends
from models.user import RegisterRequest, LoginRequest
from services.auth_service import verify_password, get_password_hash, create_access_token, get_current_user
from database import users_col, ponds_col
from datetime import datetime, timedelta
import uuid

router = APIRouter()

@router.post('/login')
async def login(body: LoginRequest):
    user = await users_col.find_one({'username': body.username})
    if not user:
        raise HTTPException(status_code=401, detail='User not found')
    if not verify_password(body.password, user['password_hash']):
        raise HTTPException(status_code=401, detail='Incorrect password')
    
    access_token_expires = timedelta(minutes=60*24*7)
    token = create_access_token(
        data={'sub': str(user['_id']), 'role': user['role']},
        expires_delta=access_token_expires
    )
    return {'token': token, 'role': user['role'], 'user_id': str(user['_id'])}

@router.post('/register')
async def register(body: RegisterRequest):
    existing = await users_col.find_one({'$or': [{'username': body.username}, {'email': body.email}]})
    if existing:
        raise HTTPException(status_code=409, detail='Username or email already taken')
    
    new_user = {
        'first_name': body.first_name,
        'last_name': body.last_name,
        'email': body.email,
        'phone': body.phone,
        'address': body.address,
        'username': body.username,
        'password_hash': get_password_hash(body.password),
        'role': 'farmer',
        'status': 'active',
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    }
    result = await users_col.insert_one(new_user)
    user_id_str = str(result.inserted_id)
    
    # Create initial pond as mentioned
    await ponds_col.insert_one({
        'pond_id': f'P-{uuid.uuid4().hex[:6].upper()}',
        'user_id': user_id_str,
        'pond_name': 'My First Pond',
        'length_m': body.pond_length,
        'width_m': body.pond_width,
        'depth_m': body.pond_depth,
        'volume_m3': body.pond_length * body.pond_width * body.pond_depth,
        'fish_species': body.fish_species,
        'status': 'healthy',
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    })
    
    return {'message': 'Account created', 'user_id': user_id_str}

@router.post('/{user_id}/fcm-token')
async def save_fcm_token(user_id: str, fcm_token: str, current_user: dict = Depends(get_current_user)):
    if str(current_user["_id"]) != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    await users_col.update_one({'_id': current_user['_id']}, {'$set': {'fcm_token': fcm_token}})
    return {'message': 'Token saved'}
