import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split

class save_model:
    def __init__(self):
        # Sample dataset
        data = {
            "Place": ["Paris", "Bali", "Tokyo", "New York", "Paris", "Bali"],
            "Time Range": ["Apr-Jun", "May-Aug", "Sep-Nov", "Dec-Feb", "Apr-Jun", "May-Aug"],
            "Days": [5, 7, 3, 4, 6, 10],
            "Avg Daily Cost": [150, 100, 200, 180, 150, 100],
            "Budget Range": [1000, 1200, 1400, 1500, 1200, 2000],
            "Air cost": [25000,20000,50000,35000,40000,30000 ],
            "Popularity": [9.2, 8.7, 9.0, 8.5, 9.2, 8.7]
        }
        self.df = pd.DataFrame(data)

        # Encoding categorical features
        self.le_place = LabelEncoder()
        self.df['Place_encoded'] = self.le_place.fit_transform(self.df['Place'])
        self.le_time = LabelEncoder()
        self.df['Time_encoded'] = self.le_time.fit_transform(self.df['Time Range'])

        # Prepare features and target
        X = self.df[['Place_encoded', 'Time_encoded', 'Days', 'Avg Daily Cost', 'Air cost','Popularity']]
        y = self.df['Budget Range']

        # Split the dataset
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # Train the model
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.model.fit(X_train, y_train)

        print("Model trained successfully!")

    def load_model(self):
        return self.model, self.le_place, self.le_time
