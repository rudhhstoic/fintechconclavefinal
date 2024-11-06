from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
import time
import pandas as pd

# Initialize the WebDriver
service = Service(executable_path="chromedriver.exe")
driver = webdriver.Chrome(service=service)
driver.get("https://www.etmoney.com/mutual-funds/all-funds-listing")
driver.find_element(By.XPATH,'//html/body/div[1]/div[6]/div[3]/div[2]/div/div[1]/div[2]/div[2]/div[2]/div[2]/div[1]/div/i').click()
driver.find_element(By.XPATH,'/html/body/div[1]/div[6]/div[3]/div[2]/div/div[1]/div[2]/div[2]/div[2]/div[2]/div[1]/div/button[1]').click()
time.sleep(5)  # Allow time for the page to load

# Arrays to store the scraped data
name = []
category = []
fund_size = []
AUM = []
curr_value = []
rpa = []
age = []
expense_ratio = []

# Load more elements if necessary
for _ in range(5):  # Adjust range for additional loading as per the site's behavior
    try:
        driver.find_element(By.ID, "load_more_nav").click()
        time.sleep(2)
    except:
        break

# Scraping fund details
schemes = driver.find_elements(By.CLASS_NAME, "scheme-name")
categories = driver.find_elements(By.CLASS_NAME, "tag")
ratios = driver.find_elements(By.CLASS_NAME, "mfFund-double")  # Adjusted selector as necessary
ages = driver.find_elements(By.CLASS_NAME, "mfFund-age")
cur = driver.find_elements(By.CLASS_NAME,"current-value" )
au = driver.find_elements(By.CLASS_NAME,"item-value")

# Processing scraped data
for scheme in schemes:
    name.append(scheme.text)

# Adjust category data collection to ensure correct parsing
for i in range(0, len(categories), 2):
    if i+1 < len(categories):
        category.append([categories[i].text, categories[i+1].text])

# Gathering expense ratio, age, and AUM
for ratio in ratios:
    va = str(ratio.text).split()
    expense_ratio.append(va[2])
for age_el in ages:
    va = str(age_el.text).split()
    age.append(va[1]+va[2])
for x in cur:
    curr_value.append(x.text)
for a in au:
    t = str(a.text)
    if 'p.a.' in t:
        rpa.append(t)
    elif 'Crs' in t:
        AUM.append(t)


print(len(name),len(category),len(AUM),len(curr_value),len(rpa),len(expense_ratio),len(age))
# Create DataFrame and export to CSV
df = pd.DataFrame({
    'Name': name,
    'Category': category,
    'AUM': AUM,
    'Current value': curr_value,
    'Return per annum': rpa,
    'Expense ratio': expense_ratio,
    'Age': age
})
df = pd.DataFrame({'Name':name, 'Category':category, 'AUM':AUM, 'Current value':curr_value, 'Return per annum':rpa, 'Expense ratio':expense_ratio, 'Age':age })
df.to_csv('Monthly.csv', index = False)
print(df)
