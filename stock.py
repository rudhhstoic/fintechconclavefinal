# Import necessary libraries
import yfinance as yf
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
import torch
import torch.nn as nn
import torch.optim as optim

# Define the GRU model class in PyTorch
class GRUModel(nn.Module):
    def __init__(self, input_size=1, hidden_size=50, output_size=1):
        super(GRUModel, self).__init__()
        self.hidden_size = hidden_size
        self.gru = nn.GRU(input_size, hidden_size, batch_first=True)
        self.fc = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        _, h = self.gru(x)  # We only need the hidden state
        h = h[-1]  # Get the last hidden state
        return self.fc(h)

class Stock:
    def create_dataset(self, data, time_step=60):
        X, y = [], []
        for i in range(time_step, len(data)):
            X.append(data[i-time_step:i])
            y.append(data[i, 0])
        return np.array(X), np.array(y)

    def get_stock_info(self, stock_name):
        stock_info = yf.Ticker(stock_name).info
        selected_info = {
            "longName": stock_info.get("longName", "N/A"),
            "industry": stock_info.get("industry", "N/A"),
            "sector": stock_info.get("sector", "N/A"),
            "marketCap": stock_info.get("marketCap", "N/A"),
            "dividendYield": stock_info.get("dividendYield", "N/A"),
            "returnOnEquity": stock_info.get("returnOnEquity", "N/A"),
            "priceToEarningsRatio": stock_info.get("trailingPE", "N/A"),
        }
        return selected_info

    def analyse(self, stock_name, start, end, epochs=50, batch_size=32):
        # Fetch stock information
        stock_info = self.get_stock_info(stock_name)

        # Fetch and preprocess stock data
        stock_data = yf.download(stock_name, start, end)[['Close']]
        
        scaler = MinMaxScaler()
        scaled_data = scaler.fit_transform(stock_data)

        X, y = self.create_dataset(scaled_data)
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, shuffle=False)

        # Convert datasets to PyTorch tensors
        X_train_tensor = torch.tensor(X_train, dtype=torch.float32)
        y_train_tensor = torch.tensor(y_train, dtype=torch.float32).view(-1, 1)
        X_test_tensor = torch.tensor(X_test, dtype=torch.float32)
        y_test_tensor = torch.tensor(y_test, dtype=torch.float32).view(-1, 1)

        # Initialize the model, loss function, and optimizer
        model = GRUModel()
        criterion = nn.MSELoss()
        optimizer = optim.Adam(model.parameters(), lr=0.001)

        # Train the model
        for epoch in range(epochs):
            model.train()
            optimizer.zero_grad()
            outputs = model(X_train_tensor)
            loss = criterion(outputs, y_train_tensor)
            loss.backward()
            optimizer.step()

            # Print loss periodically
            if (epoch+1) % 10 == 0:
                print(f'Epoch [{epoch+1}/{epochs}], Loss: {loss.item():.4f}')

        # Predict stock prices
        model.eval()
        with torch.no_grad():
            predicted_stock_price = model(X_test_tensor).numpy()
        
        # Invert scaling for final predicted and actual prices
        predicted_stock_price_full = np.zeros((predicted_stock_price.shape[0], 1))
        predicted_stock_price_full[:, 0] = predicted_stock_price[:, 0]

        predicted_stock_price_final = scaler.inverse_transform(predicted_stock_price_full).flatten()
        actual_stock_price = scaler.inverse_transform(y_test.reshape(-1, 1)).flatten()

        return {
            "stock_info": stock_info,
            "actual_stock_price": list(actual_stock_price),
            "predicted_stock_price": list(predicted_stock_price_final)
        }


