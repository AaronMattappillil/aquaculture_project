import os
import random
import pandas as pd

# Data generator script for AquaSense ML Pipeline (DO and Ammonia)

def generate_aquaculture_data(num_samples=5000):
    data = []
    
    # Generate balanced dataset including SAFE, WARNING, and DANGER scenarios
    for i in range(num_samples):
        # Scenario mix: 50% Safe, 30% Warning, 20% Danger/Critical
        scenario = random.choices(['SAFE', 'WARNING', 'DANGER'], weights=[0.5, 0.3, 0.2])[0]
        
        if scenario == 'SAFE':
            temp = random.uniform(24, 30)
            ph = random.uniform(6.8, 8.2)
            turbidity = random.uniform(5, 30)
            light = random.uniform(200, 800)
            water_level = random.uniform(1.5, 2.5)
            
            # Target Variables
            do = random.uniform(6.5, 8.5)
            nh3 = random.uniform(0.01, 0.04)
            
        elif scenario == 'WARNING':
            temp = random.uniform(20, 34)
            ph = random.uniform(6.0, 8.8)
            turbidity = random.uniform(30, 60)
            light = random.uniform(100, 1000)
            water_level = random.uniform(1.0, 3.0)
            
            do = random.uniform(4.0, 6.0)
            nh3 = random.uniform(0.05, 0.15)
            
        else: # DANGER
            temp = random.choices([random.uniform(15, 20), random.uniform(34, 40)])[0]
            ph = random.choices([random.uniform(4.0, 6.0), random.uniform(8.8, 10.0)])[0]
            turbidity = random.uniform(60, 150)
            light = random.uniform(0, 1200)
            water_level = random.uniform(0.5, 3.5)
            
            do = random.uniform(1.0, 4.0)
            nh3 = random.uniform(0.2, 1.0)
            
        data.append([temp, ph, turbidity, light, water_level, do, nh3])
        
    df = pd.DataFrame(data, columns=['temperature', 'ph', 'turbidity', 'light', 'water_level', 'do', 'nh3'])
    return df

if __name__ == "__main__":
    print("Generating synthetic dataset...")
    df = generate_aquaculture_data(10000)
    
    os.makedirs('data', exist_ok=True)
    df.to_csv('data/synthetic_aquaculture_data.csv', index=False)
    print("Dataset saved to data/synthetic_aquaculture_data.csv")
    print(f"Dataset shape: {df.shape}")
