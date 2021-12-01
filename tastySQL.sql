-- This SQL file contains code for DDL, cleaning and exploratory data analysis (EDA) --



--------------------------- DDL -----------------------------------------------------------------------------------------------------------------

-- VARCHAR used for all fields (dtype stored when webscraping) and for sql data cleaning later on.

CREATE TABLE public.recipes(
	url 		VARCHAR(120),
	recipename  VARCHAR(120),
	numtips 	VARCHAR(10),
	percentwma  VARCHAR(10),
	totaltime   VARCHAR(20),
	amtservings VARCHAR(10),
	calories 	VARCHAR(10),
	fat 		VARCHAR(10),
	carbs		VARCHAR(10),
	fiber		VARCHAR(10),
	sugar		VARCHAR(10),
	protein		VARCHAR(10),
	CONSTRAINT recipes_pkey PRIMARY KEY (url)
);


CREATE TABLE public.ingredients(
	url 		VARCHAR(120),
	ingredient	VARCHAR(200),
	amount		VARCHAR(200),
	CONSTRAINT ingredients_fkey FOREIGN KEY (url) REFERENCES recipes (url)
		ON DELETE CASCADE
);

CREATE TABLE public.topics(
	url 		VARCHAR(120),
	meal		VARCHAR(120),
	diet		VARCHAR(120),
	culture		VARCHAR(120),
	CONSTRAINT topics_fkey FOREIGN KEY (url) REFERENCES recipes (url)
		ON DELETE CASCADE
);


------------------------- Data cleaning ----------------------------------------------------------------------------------------------------------

------------------ RECIPES DATA for cleaning

----- NUMTIPS

-- convert numtips to int

UPDATE
	recipes
SET
	numtips = REPLACE (
		numtips,
		'g',
		''
	);
	
-- delete numtips None

DELETE FROM recipes
WHERE numtips = 'None';

	
-- to_number numtips

ALTER TABLE recipes
	ALTER COLUMN numtips TYPE INT
	USING numtips::integer
	;
	
	
	
	
----- PERCENTWMA (% Would make again)

SELECT *
FROM recipes
WHERE percentwma = 'None';

-- delete percentwma

DELETE FROM recipes
WHERE percentwma = 'None';
	
-- Remove %

UPDATE
	recipes
SET
	percentwma = REPLACE(
		percentwma,
		'%',
		''
	);

-- Convert varchar to int

ALTER TABLE recipes
	ALTER COLUMN percentwma TYPE INT
	USING percentwma::integer
	;




----- TOTALTIME

-- cases: None, XX minutes, under 30 min, X hr, X hr XX min. Convert all cases to units of minutes in integer type. Under 30 min will be 30 min

-- drop None

DELETE FROM recipes
WHERE totaltime = 'None';

-- Under 30 minutes

UPDATE
	recipes
SET
	totaltime = REPLACE(
		totaltime,
		'Under 30 minutes',
		'30'
	);

-- XX minutes

UPDATE
	recipes
SET
	totaltime = REPLACE(
		totaltime,
		' minutes',
		''
	);

-- X hr XX min

UPDATE 
	recipes
SET
	totaltime = (CAST(LEFT(totaltime, 2) AS integer) * 60) + CAST(
																RIGHT(
																	REPLACE(totaltime,
																    ' min',
																    ''),
																2)
															 AS integer)
WHERE totaltime ILIKE '%hr%' and totaltime ILIKE '%min%';

-- X hr

UPDATE
	recipes
SET
	totaltime = (CAST(LEFT(totaltime, 2) AS integer) * 60)
WHERE totaltime ILIKE '%hr%';

-- Convert from varchar to int

ALTER TABLE recipes
	ALTER COLUMN totaltime TYPE INT
	USING totaltime::integer
	;


----- AMTSERVINGS

-- Convert None to 0 and convert from varchar to int

UPDATE
	recipes
SET
	amtservings = REPLACE(
		amtservings,
		'None',
		'0')
	;

ALTER TABLE recipes
	ALTER COLUMN amtservings TYPE INT
	USING amtservings::integer
	;

----- NUTRITIONAL VALUES
-- calories, fat, carbs, fiber, sugar, protein
-- All similar cleaning

-- Drop None

DELETE FROM recipes
WHERE calories = 'None'
	OR
	fat = 'None'
	OR
	carbs = 'None'
	OR
	fiber = 'None'
	OR
	sugar = 'None'
	OR
	protein = 'None'
	;

-- Replace g with ''

UPDATE
	recipes
SET
	fat = REPLACE(
		fat,
		'g',
		''),
	carbs = REPLACE(
		carbs,
		'g',
		''),
	fiber = REPLACE(
		fiber,
		'g',
		''),
	sugar = REPLACE(
		sugar,
		'g',
		''),
	protein = REPLACE(
		protein,
		'g',
		'')
	;

-- Convert from varchar to int
ALTER TABLE recipes
	ALTER COLUMN calories TYPE INT			 
	USING calories::integer
	;
ALTER TABLE recipes
	ALTER COLUMN fat TYPE INT			 
	USING fat::integer
	;
ALTER TABLE recipes
	ALTER COLUMN carbs TYPE INT			 
	USING carbs::integer
	;
ALTER TABLE recipes
	ALTER COLUMN fiber TYPE INT			 
	USING fiber::integer
	;
ALTER TABLE recipes
	ALTER COLUMN sugar TYPE INT			 
	USING sugar::integer
	;
ALTER TABLE recipes
	ALTER COLUMN protein TYPE INT			 
	USING protein::integer
	;

select *
from recipes;

----------------------- TOPICS DATA for cleaning
-- convert null to Other

UPDATE
	topics
SET
	meal = COALESCE(
		meal,
		'Other'),
	diet = COALESCE(
		diet,
		'Other'),
	culture = COALESCE(
		culture,
		'Other')
	;
	
select *
from topics;


-- delete urls of recipes that were dropped

DELETE FROM topics
WHERE url NOT IN (SELECT url
				  FROM recipes)
				  ;





-------------------------- INGREDIENTS DATA for cleaning
------- amount and ingredient
---- cases:
-- fractions: x/y units, Z x/y units
-- no units (ie. to taste, for garnish) These cases are mixed up in columns ingredient and amount due to webscraping error
-- normal: X units, X
-- None: no listed amount in recipe
---- Ingredient
-- when amount is none, the string format of ingredient contains [''], which needs to be removed


-- remove [''] from ingredient when amount is None
UPDATE
	ingredients
SET
	ingredient = REPLACE(
		ingredient,
		E'[\'',
		'')
	;
	
UPDATE
	ingredients
SET
	ingredient = REPLACE(
		ingredient,
		E'\']',
		'')
	;

-- Switch Amount and Ingredient values for no units case (mixed up from webscraping error)

-- only select for cases where first character is not a number and is a letter (fractions 1/2, 1/4 are not considered numbers and is not considered a letter)


UPDATE
	ingredients
SET
	ingredient = amount,
	amount = ingredient
WHERE
	NOT LEFT(amount, 1) ~ '^[0-9\.]+$'
	AND
	LEFT(amount, 1) ~* '[a-z]'
	AND
	amount != 'None'
	;

SELECT *
FROM ingredients;

-- Drop rows in ingredients of recipes that were dropped

DELETE FROM ingredients
WHERE url NOT IN (SELECT url
				  FROM recipes)
				  ;





------------------------------- Tasty.co Recipes EDA ------------------------------------------------------------------------------------------------------

-- See all tables

select *
from ingredients;

select *
from recipes;

select *
from topics;

----- EDA with topics


SELECT meal, 
	   ROUND(AVG(numtips), 2) AS averagetips, 
	   ROUND(AVG(percentwma), 2) AS averagewma, 
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	numtips != 0
	AND
	percentwma != 0
GROUP BY meal;

SELECT diet, 
	   ROUND(AVG(numtips), 2) AS averagetips, 
	   ROUND(AVG(percentwma), 2) AS averagewma,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	numtips != 0
	AND
	percentwma != 0
GROUP BY diet;

SELECT culture, 
	   ROUND(AVG(numtips), 2) as averagetips, 
	   ROUND(AVG(percentwma), 2) AS averagewma, 
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	numtips != 0
	AND
	percentwma != 0
GROUP BY culture;

-- dinner and dessert, healthy, and American food are the most prominent type of recipes on tasty
-- Noticable trend, the more posts on a particular food topic, the higher the average number of tips for a recipe

-- TOTAL time with topics

SELECT meal, 
	   ROUND(AVG(totaltime), 2) AS averagetime,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	totaltime != 0
GROUP BY meal;

SELECT culture, 
	   ROUND(AVG(totaltime), 2) AS averagetime,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	totaltime != 0
GROUP BY culture;

SELECT diet, 
	   ROUND(AVG(totaltime), 2) AS averagetime,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	totaltime != 0
GROUP BY diet;

-- Amount of Servings

SELECT meal, 
	   ROUND(AVG(amtservings), 2) AS averageamtservings,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	amtservings != 0
GROUP BY meal;

SELECT culture, 
	   ROUND(AVG(amtservings), 2) AS averageamtservings,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	amtservings != 0
GROUP BY culture;

SELECT diet, 
	   ROUND(AVG(amtservings), 2) AS averageamtservings,
	   COUNT(*) AS count
FROM topics a, recipes b
WHERE a.url = b.url
	AND
	amtservings != 0
GROUP BY diet;


-- healthy and nutrients

SELECT diet,
	   ROUND(AVG(calories), 2) AS avgcals, 
	   ROUND(AVG(fat), 2) AS avgfat, 
	   ROUND(AVG(carbs), 2) AS avgcarbs, 
	   ROUND(AVG(fiber), 2) AS avgfiber,
	   ROUND(AVG(sugar), 2) AS sugar,
	   ROUND(AVG(protein), 2) AS protein
FROM topics a, recipes b
WHERE a.url = b.url
GROUP BY diet;

-- Number of interesting points:
-- low-carb-meals of course has a lower carb average per recipe than the others
-- vegan has the highest fiber (which makes sense since vegetables are high in fiber)

SELECT culture,
	   ROUND(AVG(calories), 2) AS avgcals, 
	   ROUND(AVG(fat), 2) AS avgfat, 
	   ROUND(AVG(carbs), 2) AS avgcarbs, 
	   ROUND(AVG(fiber), 2) AS avgfiber,
	   ROUND(AVG(sugar), 2) AS sugar,
	   ROUND(AVG(protein), 2) AS protein
FROM topics a, recipes b
WHERE a.url = b.url
GROUP BY culture;

-- Interesting to see that italian food on average has more carbs and protein. A lot of their food contains pasta, which is high in carbs

SELECT meal,
	   ROUND(AVG(calories), 2) AS avgcals, 
	   ROUND(AVG(fat), 2) AS avgfat, 
	   ROUND(AVG(carbs), 2) AS avgcarbs, 
	   ROUND(AVG(fiber), 2) AS avgfiber,
	   ROUND(AVG(sugar), 2) AS sugar,
	   ROUND(AVG(protein), 2) AS protein
FROM topics a, recipes b
WHERE a.url = b.url
GROUP BY meal;

-- Dessert has the most sugar

-- numtips with topics

SELECT meal, diet, culture, COUNT(*) AS counted, ROUND(AVG(numtips), 2) AS avgnumtips,
	   ROUND(AVG(calories), 2) AS avgcals, 
	   ROUND(AVG(fat), 2) AS avgfat, 
	   ROUND(AVG(carbs), 2) AS avgcarbs, 
	   ROUND(AVG(fiber), 2) AS avgfiber,
	   ROUND(AVG(sugar), 2) AS avgsugar,
	   ROUND(AVG(protein), 2) AS avgprotein
FROM topics a, recipes b
WHERE a.url = b.url
GROUP BY meal, diet, culture
ORDER BY counted DESC, AVG(numtips) DESC;


-- Find common ingredients (easiest to make recipes and see ratings/popularity)

CREATE OR REPLACE VIEW ingredientcount AS
	SELECT ingredient, COUNT(*) AS ingrecount
	FROM ingredients
	GROUP BY ingredient
	ORDER BY COUNT(ingredient) DESC;

SELECT *
FROM ingredientcount;


-- See Recipes and the popularity of ingredients used

CREATE OR REPLACE VIEW recipeingredientpop AS
	SELECT recipename, ROUND(AVG(numtips), 0) AS numtips, ROUND(AVG(countingredients), 2) AS commoningredientusage
	FROM recipes a, ingredients b, (SELECT ingredient, COUNT(*) AS countingredients
									FROM ingredients
									GROUP BY ingredient
									ORDER BY COUNT(ingredient) DESC) AS c
	WHERE a.url = b.url AND b.ingredient = c.ingredient
	GROUP BY recipename
	ORDER BY numtips DESC, commoningredientusage DESC;

SELECT *
FROM recipeingredientpop;
