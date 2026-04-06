import logging
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.core.security import create_access_token, hash_password, verify_password
from app.db.mongo import ponds_collection, users_collection
from app.models.pond import PondInDB
from app.models.user import UserInDB
from app.schemas.auth import AuthResponse, ForgotPasswordRequest, SignupRequest, LoginJSONRequest

_logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse)
async def register(req: SignupRequest):
    # 1. Check for existing user
    if await users_collection().find_one({"username": req.username}):
        _logger.warning(f"Registration failed: Username {req.username} already exists.")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists")
    if await users_collection().find_one({"email": req.email}):
        _logger.warning(f"Registration failed: Email {req.email} already exists.")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists")

    try:
        # 2. Hash password and create user
        hashed_password = hash_password(req.password)
        user = UserInDB(
            first_name=req.first_name,
            last_name=req.last_name,
            email=req.email,
            address=req.address,
            phone=req.phone,
            username=req.username,
            password_hash=hashed_password,
            role="farmer"
        )
        
        user_doc = user.model_dump(by_alias=True, exclude={"id"})
        result = await users_collection().insert_one(user_doc)
        user_id = str(result.inserted_id)

        # 3. Create default pond
        pond = PondInDB(
            user_id=user_id,
            name="Default Pond",
            length_m=req.pond_length,
            width_m=req.pond_width,
            height_m=req.pond_height,
            fish_species=req.fish_species,
        )
        await ponds_collection().insert_one(pond.model_dump(by_alias=True, exclude={"id"}))

        _logger.info(f"User registered successfully: {req.username}")
        token = create_access_token(req.username)
        return AuthResponse(
            id=user_id, username=req.username, role="farmer", access_token=token
        )
    except Exception as e:
        _logger.error(f"Internal error during registration: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Registration failed")


@router.post("/login", response_model=AuthResponse)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    identifier = form_data.username
    password = form_data.password

    _logger.info(f"Login attempt for: {identifier}")
    doc = await users_collection().find_one({
        "$or": [{"email": identifier}, {"username": identifier}]
    })

    if not doc:
        _logger.warning(f"Login failure: User {identifier} not found.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    doc["_id"] = str(doc["_id"])
    user = UserInDB.model_validate(doc)

    # Use the hybrid verification strategy from security.py
    if not verify_password(password, user.password_hash):
        _logger.warning(f"Login failure: Incorrect password for {identifier}.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    _logger.info(f"Login successful: {user.username} (Role: {user.role})")
    token = create_access_token(user.username)

    return AuthResponse(
        id=user.id or "",
        username=user.username,
        role=user.role,
        access_token=token,
    )


@router.post("/login-json", response_model=AuthResponse)
async def login_json(req: LoginJSONRequest):
    _logger.info(f"JSON Login attempt for: {req.username}")
    doc = await users_collection().find_one({
        "$or": [{"email": req.username}, {"username": req.username}]
    })

    if not doc:
        _logger.warning(f"Login failure (JSON): User {req.username} not found.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    doc["_id"] = str(doc["_id"])
    user = UserInDB.model_validate(doc)

    # Use the hybrid verification strategy from security.py
    if not verify_password(req.password, user.password_hash):
        _logger.warning(f"Login failure (JSON): Incorrect password for {req.username}.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if doc.get("status", "active").upper() == "BANNED":
        _logger.warning(f"Login blocked: User {req.username} is banned.")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Your account has been banned. Contact support."
        )

    _logger.info(f"Login successful (JSON): {user.username}")
    token = create_access_token(user.username)

    return AuthResponse(
        id=user.id or "",
        username=user.username,
        role=user.role,
        access_token=token,
    )


@router.post("/forgot-password")
async def forgot_password(req: ForgotPasswordRequest):
    user = await users_collection().find_one({
        "$or": [
            {"email": req.email_or_username},
            {"username": req.email_or_username}
        ]
    })

    # Return success regardless of existence to prevent enumeration attacks
    if not user:
        return {"message": "If an account exists, a reset link has been sent."}

    import secrets
    reset_token = secrets.token_urlsafe(32)
    _logger.debug(f"Password reset triggered for {user['email']}.")

    return {"message": "If an account exists, a reset link has been sent."}