"""
Run once to seed default fish species into MongoDB.
Usage: python seed_fish_species.py
"""
import asyncio
import sys
import os

# Add the current directory to sys.path so 'app' can be found
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), ".")))

from app.db.mongo import fish_species_collection, init_db_indexes

DEFAULT_SPECIES = [
    {
        "name": "Tilapia",
        "temperature_min": 24.0,
        "temperature_max": 30.0,
        "ph_min": 6.5,
        "ph_max": 8.5,
        "turbidity": 10.0,
        "is_custom": False,
        "created_by": None,
    },
    {
        "name": "Catfish",
        "temperature_min": 22.0,
        "temperature_max": 28.0,
        "ph_min": 6.0,
        "ph_max": 8.0,
        "turbidity": 15.0,
        "is_custom": False,
        "created_by": None,
    },
    {
        "name": "Shrimp",
        "temperature_min": 23.0,
        "temperature_max": 30.0,
        "ph_min": 7.5,
        "ph_max": 8.5,
        "turbidity": 5.0,
        "is_custom": False,
        "created_by": None,
    },
    {
        "name": "Carp",
        "temperature_min": 18.0,
        "temperature_max": 25.0,
        "ph_min": 6.5,
        "ph_max": 8.5,
        "turbidity": 20.0,
        "is_custom": False,
        "created_by": None,
    },
]


async def seed():
    print("Initializing database indexes...")
    await init_db_indexes()

    collection = fish_species_collection()

    # Drop old collection to migrate to new flattened schema
    print("Dropping existing fish_species collection for migration...")
    await collection.drop()

    result = await collection.insert_many(DEFAULT_SPECIES)
    print(f"Seeded {len(result.inserted_ids)} fish species.")


if __name__ == "__main__":
    asyncio.run(seed())
