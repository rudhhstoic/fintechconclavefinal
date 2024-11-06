from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time
import pandas as pd

#returns = input("Monthly/Lumpsum ?")
#amt = input("Enter amt:")
#dur = input("Duration")

service = Service(executable_path="chromedriver.exe")
driver = webdriver.Chrome(service =service)
driver.get("https://www.etmoney.com/mutual-funds/all-funds-listing")  # Adjust this to the mutual funds page URL if different
time.sleep(5)  # Wait for the page to load

#driver.find_element(By.ID,"investment-mode").click()
#driver.find_element(By.XPATH,"//*[@id='investment-mode-dropdown']/div/div/div/ul/li[2]").click()
driver.find_element(By.XPATH,'//html/body/div[1]/div[6]/div[3]/div[2]/div/div[1]/div[2]/div[2]/div[2]/div[2]/div[1]/div/i').click()
driver.find_element(By.XPATH,'/html/body/div[1]/div[6]/div[3]/div[2]/div/div[1]/div[2]/div[2]/div[2]/div[2]/div[1]/div/button[1]').click()
time.sleep(5)

name =[]
category =[]
fund_size =[]
AMC = []
curr_value =[]
rpa = []
age =[]
expense_ratio =[]
all =[]

# Locate and fetch fund details
for i in range(0):
    driver.find_element(By.ID,"load_more_nav").click()
    time.sleep(2)
scheme = driver.find_elements(By.CLASS_NAME,"scheme-name")
cate = driver.find_elements(By.CLASS_NAME,"tag")
'''amc = driver.find_elements(By.CLASS_NAME,"col-md-3.col-sm-4.col-xs-4.flex-col")'''
ratio = driver.find_elements(By.CLASS_NAME,"col-md-3 col-sm-4 col-xs-4 flex-col mfFund-double")
ages = driver.find_elements(By.CLASS_NAME,"col-md-3 col-sm-4 col-xs-4 flex-col hidden-xs hidden-sm mfFund-age")
aum = driver.find_elements(By.CLASS_NAME,"col-md-3 col-sm-4 col-xs-4 flex-col")

for i in scheme:
    v = str((i.text).split(','))
    name.append(v[2:len(v)-2])
for i in range(0,len(cate),2):
    v = [(cate[i].text).split(' '),(cate[i+1].text).split(' ')]
    category.append(v)
for i in range(0,len(ratio),2):
    v = str((i.text).split(','))
    expense_ratio.append(v)
for i in range(0,len(ages),2):
    v = str((i.text).split(','))
    age.append(v)

'''
#For lumpsum 
amc = driver.find_elements(By.CLASS_NAME,"index-value")
for i in amc:
    v = str((i.text).split(','))
    print(v)
    if "Genius" not in v[2:len(v)-2]:
        if "['']" not in v:
            v = v[2:len(v)-2]
            v = v.replace("', '","")
            all.append(v)'''
i=0
for j in all:
    if i==0:
        AMC.append(j)
        i=1
    elif i==1:
        curr_value.append(j)
        i=2
    elif i==2:
        rpa.append(j)
        i=0

for i in aum:
    v = str((i.text).split(','))
    print(v)
    if 'AUM' in v:
        v = v[2:len(v)-2]
        v = v.replace("', '","")
        AMC.append(v.split('\\n')[1])
    elif 'Current' in v:
        v = v[2:len(v)-2]
        curr_value.append(v.split('\\n')[1])
    elif 'Return' in v:
        v = v[2:len(v)-2]
        rpa.append(v.split('\\n')[1])

print(len(name),len(category),len(AMC),len(curr_value),len(rpa),len(expense_ratio),len(age))
df = pd.DataFrame({'Name':name, 'Category':category, 'AUM':AMC, 'Current value':curr_value, 'Return per annum':rpa, 'Expense ratio':expense_ratio, 'Age':age })
df.to_csv('Monthly.csv', index = False)
print(df)
    