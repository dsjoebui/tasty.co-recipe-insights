# This webscraping script is used to scrape all pertinent information on tasty.co recipes

import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from csv import reader
import csv

# start up webdriver

PATH = "C:\Program Files (x86)\chromedriver.exe"
s = Service(PATH)
op = webdriver.ChromeOptions()
op.headless = True
#op.add_extension(r'C:\Users\buij5\Desktop\Tasty Recipes Project\extension_3_11_2_0.crx')
driver = webdriver.Chrome(service=s, options=op)
time.sleep(5)

# RECIPES CSV
recipefilename = 'tastyrecipes.csv'
recipe_csv = open(recipefilename, 'w', encoding="utf-8", newline='') # create file
recipecsv_writer = csv.writer(recipe_csv) # get file writer
recipecsv_writer.writerow(['url', 'recipename', 'numtips', 'percentwma', 'totaltime', 'amtservings', 'calories', 'fat', 'carbs', 'fiber', 'sugar', 'protein']) # create columns

# INGREDIENTS CSV
ingredientsfilename = 'tastyingredients.csv'
ingredients_csv = open(ingredientsfilename, 'w', encoding="utf-8", newline='') # create file
ingredientscsv_writer = csv.writer(ingredients_csv) # get file writer
ingredientscsv_writer.writerow(['url', 'ingedient', 'amount']) # create columns



# Get URLs from recipeurls.csv
readcsv = open('recipeurls.csv', 'r')
csvreader = reader(readcsv)
next(csvreader)


# create loop to visit and webscrape every url listed in recipeurls.csv
for i in csvreader:
	driver.get(i[1])

	# recipe name
	try:
		recipename = driver.find_element(by=By.CLASS_NAME, value='recipe-name.extra-bold.xs-mb05.md-mb1')
		recipename = recipename.text
	except:
		recipename = 'None'
	# number of tips
	try:
		numtips = driver.find_element(by=By.CLASS_NAME, value='tips-count-heading.extra-bold.caps.xs-text-5')
		numtips = numtips.text.split()[0]
	except:
		numtips = 'None'

	# % would make again
	try:
	    percentwma = driver.find_element(by=By.CLASS_NAME, value='tips-score-heading.extra-bold.caps.xs-text-5')
	    percentwma = percentwma.text.split()[0]
	except:
		percentwma = 'None'

	# totaltime
	try:
		totaltimemain = driver.find_element(by=By.CLASS_NAME, value='recipe-time.xs-col-12.xs-pr3.md-pr2')
		totaltime = totaltimemain.find_element(by=By.CLASS_NAME, value='xs-text-4.xs-hide.md-block')
		totaltime = totaltime.get_attribute('innerText')
	except:
		try:
			totaltimemain = driver.find_element(By.CLASS_NAME, value='recipe-time-container.xs-flex.xs-mt2.md-mt0.xs-mx2.xs-relative.xs-b0.md-b2')
			totaltime = totaltimemain.get_attribute('innerText')
		except:
			totaltime = 'None'

	# Amount of servings
	try:
		amtservings = driver.find_element(by=By.CLASS_NAME, value='servings-display.xs-text-2.xs-mb2')
		amtservings = amtservings.get_attribute("innerText").split()[1]
	except:
		amtservings = 'None'


	# Nutrition

	try:
		nutrients = driver.find_elements(by=By.CLASS_NAME, value='list-unstyled.xs-mb1')
		nutrientlist = []
		for x in nutrients:
			nutrient = (x.get_attribute("innerText").split()[1]) # get value
			nutrientlist.append(nutrient)
		calories = nutrientlist[0] # calories
		fat = nutrientlist[1] # fat
		carbs = nutrientlist[2] # carbs
		fiber = nutrientlist[3] # fiber
		sugar = nutrientlist[4] # sugar
		protein = nutrientlist[5] # protein
	except:
		calories = 'None'
		fat = 'None'
		carbs = 'None'
		fiber = 'None'
		sugar = 'None'
		protein = 'None'


	# write data into csv file
	recipecsv_writer.writerow([i[1], recipename, numtips, percentwma, totaltime, amtservings, calories, fat, carbs, fiber, sugar, protein])

# ------ 

	# Ingredients
	ingreds = driver.find_elements(by=By.XPATH, value='//div[@class="recipe-content clearfix xs-hide md-flex"]//li[@class="ingredient xs-mb1 xs-mt0"]')
	for x in ingreds:
		string = x.get_attribute('innerHTML')
		try:
			a = string.split('<span')[0]
		except:
			a = string

		b = a.split('<!-- -->')
		try: # amount can be missing
			amount = b[0].strip() 
			ingred = b[1].strip()
		except:
			amount = 'None'
			ingred = b

		ingredientscsv_writer.writerow([i[1], ingred, amount])


recipe_csv.close()
ingredients_csv.close()

driver.quit() # close the browser

