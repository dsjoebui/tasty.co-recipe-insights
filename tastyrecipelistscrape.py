# This webscraping script is used to scrape urls of tasty.co recipes under various topics

import time
import csv
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By


# Start up web driver

PATH = "C:\Program Files (x86)\chromedriver.exe"
s = Service(PATH)
op = webdriver.ChromeOptions()
op.add_extension(r'C:\Users\buij5\Desktop\Tasty Recipes Project\extension_3_11_2_0.crx')
driver = webdriver.Chrome(service=s, options=op)

time.sleep(10)

# ------- TOPIC URLS ---> Creates 3 csv files: meal_tastyscrape.csv, diet_tastyscrape.csv, culture_tastyscrape.csv

prefixurl = 'https://tasty.co/topic/'

# MEALS

suffixmeal = 		['breakfast',
					 'lunch',
					 'dinner',
					 'desserts',
					 'snacks']

# DIET

suffixdiet = 		['healthy',
			         'best-vegetarian',
			         'low-carb-meals',
			         'keto',
			         'vegan']

# CULTURE

suffixculture =     ['american',
				     'mexican',
				     'japanese',
				     'chinese',
				     'italian']


# --- File management

suffixeslist = [suffixmeal, 
				suffixdiet, 
				suffixculture]

topics = ['meal', 
		  'diet', 
		  'culture']

for topic, suffixes in zip(topics, suffixeslist):
	csv_filename = topic + '_tastyscrape.csv'
	csv_file = open(csv_filename, 'w', encoding="utf-8", newline='') # create file
	csv_writer = csv.writer(csv_file) # get file writer
	csv_writer.writerow([topic, 'URL']) # create columns



	for suffix in suffixes:
		url = prefixurl + suffix


# --- SELENIUM gets URL

		driver.get(url)
		time.sleep(5)


		# Click the Show More Recipes button until all recipes are shown

		# initial click (different button)
		firstbtn = driver.find_element(by=By.ID, value='init-show-more')
		firstbtn.click()
		time.sleep(5)

		# button after initial click
		try:
			for i in range(1000):
				showmorebtn = driver.find_element(by=By.XPATH, value='//amp-list-load-more[@class="xs-flex xs-px1 xs-mt2 amp-visible"]//button[@class="button button--tasty bold xs-block xs-mx-auto xs-col-12 md-width-auto analyt-content-action"]')
				showmorebtn.click()
				time.sleep(5)
		except:
			pass

		# Get URLS of recipes

		main = driver.find_element(by=By.ID, value='content')
		URLs = main.find_elements(by=By.TAG_NAME, value='a')
		for URL in URLs:
			try:
				urllink = URL.get_attribute('href')
				csv_writer.writerow([suffix, urllink])
			except:
				pass


	

	csv_file.close() 


driver.quit() # close the browser



# ----------------- Expand recipe compilation tasty links --> creates 3 csv files of full tastyrecipe urls
# Some recipe urls link to compilation of recipes containing multiple recipes within. These recipe compilation URLs must be further processed and webscraped

# Start up web driver

PATH = "C:\Program Files (x86)\chromedriver.exe"
s = Service(PATH)
op = webdriver.ChromeOptions()
op.headless = True
driver = webdriver.Chrome(service=s, options=op)

topics = ['meal', 
		  'diet', 
		  'culture']


# --- File management

for x in topics:
	csvfilename = 'full_' + x + '_tastyscrape.csv'

	csv_file = open(csvfilename, 'w', encoding="utf-8", newline='') # create file
	csv_writer = csv.writer(csv_file) # get file writer

	readfilename = x + '_tastyscrape.csv'
	readcsv = open(readfilename, 'r') # read file
	csvreader = reader(readcsv)

# --- selenium

	for i in csvreader:
		if 'compilation' in i[1]: # i[1] is the URL, i[0] is the topic
			driver.get(i[1])
			time.sleep(5)
			main = driver.find_element(by=By.CLASS_NAME, value='feed')
			URLs = main.find_elements(by=By.TAG_NAME, value='a')
			for URL in URLs:
				try:
					urllink = URL.get_attribute('href')
					csv_writer.writerow([i[0], urllink])
			# SEARCH ALL URL LINKS
				except:
					csv_writer.writerow([i[0], i[1]])
		else:
			csv_writer.writerow([i[0], i[1]])


	csv_file.close()

driver.quit() # close the browser
