/* ### Agregar el primer valor de algo a toda la columna ####

SELECT FIRST_VALUE(order_time) OVER (ORDER BY order_time ASC) as DATE
FROM dbo.Orders
*/

/* ### Separar con coma strings ###
SELECT name,value ingredient 
FROM dbo.Pizza CROSS APPLY STRING_SPLIT(ingredients, ',')
*/

/* ### Ejemplo de fecha ###
DECLARE @LastMonth DATETIME
SET @LastMonth = DATEADD(month, DATEDIFF(month, 0, (SELECT MAX(order_time) FROM dbo.Orders)), 0)

(SELECT piz.name, ord.order_time, piz.ingredients
FROM dbo.Orders ord, dbo.Pizza piz
WHERE piz.id = ord.Pizza_id AND 
	  order_time >= DATEADD(mm, -6, @LastMonth) 
      AND order_time < @LastMonth)
*/
--====================================================================================
--==================   EXCERSICE 1 ===================================================

--Write a query to print a new pizza recipe that includes the most used 5
--ingredients in all the ordered pizzas in the past 6 months

--====================================================================================


--Seteo la fecha de la ultima orden

DECLARE @LastMonth DATETIME
SET @LastMonth = DATEADD(month, DATEDIFF(month, 0, (SELECT MAX(order_time) FROM dbo.Orders)), 0)


SELECT l.name as Ingredients_New_Pizza

FROM	
		--4. Subquery: 
		(SELECT TOP 5 fin.name, count(fin.name) as Total
		FROM

			--3. Subquery:
			(SELECT num.name as Pizza_name,num.ingredient, ing.name
			 FROM dbo.Ingredients ing,

				 --2. Subquery: 
				 (SELECT name,value ingredient 
				  FROM 

					  --1. Subquery:
					  (SELECT piz.name, ord.order_time, piz.ingredients
					  FROM dbo.Orders ord, dbo.Pizza piz
					  WHERE piz.id = ord.Pizza_id AND
					  order_time >= DATEADD(mm, -6, @LastMonth)
					  AND order_time < @LastMonth) sel 
					  --1. END
					  CROSS APPLY STRING_SPLIT(sel.ingredients, ',')) num
				 --2. END
			WHERE ing.id = num.ingredient) fin
			--3. END
		
		GROUP BY (fin.name)
		ORDER BY Total DESC) l
		--4. END


--====================================================================================
--==================   EXCERSICE 2 ===================================================

--Help the cook by generating an alphabetically ordered comma separated ingredient list 
--for each ordered pizza and add a 2x in front of any ingredient that is requested as 
--extra and is present in the standard recipe too. 
--For example: 
--The recipe for order_id = 5 would be: "2xBacon, BBQ Sauce, Beef, Cheese, Chicken, 
--Mushrooms, Pepperoni, Salami" 


--====================================================================================

SELECT order_id, pizza_id
FROM dbo.Orders



Declare @Numbers AS Nvarchar(MAX) -- It must not be MAX if you have few numbers
SELECT  @Numbers = COALESCE(@Numbers + ', ', '') + name
FROM   dbo.Pizza where name IS NOT NULL ORDER BY name ASC

SELECT @Numbers



SELECT num.name as Pizza_name,num.ingredient, ing.name, num.order_id,exclusions,extras
		FROM dbo.Ingredients ing,

						 -- Subquery: 
						 (SELECT name,value ingredient ,sel.order_id,exclusions,extras
						  FROM 

							  --Subquery:
							  (SELECT order_id,ord.exclusions,ord.extras,piz.name, ord.order_time, piz.ingredients
							  FROM dbo.Orders ord, dbo.Pizza piz
							  WHERE piz.id = ord.Pizza_id
							 ) sel 
							  --
							  CROSS APPLY STRING_SPLIT(sel.ingredients, ',')) num
						 --
					WHERE ing.id = num.ingredient
		ORDER BY order_id, Pizza_name 