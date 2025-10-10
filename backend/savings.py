import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import OrdinalEncoder
from sklearn.model_selection import train_test_split

class save_model:
    def __init__(self):
        # Sample dataset
        data = pd.read_csv(r"D:\Project\fintechconclavefinal\backend\uploads\budgeting_data_processed.csv")
        self.df = pd.DataFrame(data)

        # Encoding categorical features
        self.le_place = OrdinalEncoder(handle_unknown='use_encoded_value', unknown_value=-1)
        self.df['Place_encoded'] = self.le_place.fit_transform(self.df['Place'].values.reshape(-1, 1)).flatten()
        self.le_time = OrdinalEncoder(handle_unknown='use_encoded_value', unknown_value=-1)
        self.df['Time_encoded'] = self.le_time.fit_transform(self.df['Time Range'].values.reshape(-1, 1)).flatten()

        # Prepare features and target
        X = self.df[['Place_encoded', 'Time_encoded', 'Days', 'Avg Daily Cost', 'Air Cost','Popularity']]
        y = self.df['Budget Range']

        # Split the dataset
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # Train the model
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.model.fit(X_train, y_train)

        print("Model trained successfully!")

    def load_model(self):
        return self.model, self.le_place, self.le_time
