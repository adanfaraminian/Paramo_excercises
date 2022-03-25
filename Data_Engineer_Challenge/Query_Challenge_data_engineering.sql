/* ====================== Data Engineering Challenge =================================
=====================================================================================

This file shows the solution to the data engineering challenge. The operation of the 
main query and its subqueries are described in it. The "pizza_schema.sql" file shows 
the schema to load the data. */


/*==================   EXCERSICE 1 ===================================================
--====================================================================================

Write a query to print a new pizza recipe that includes the most used 5
ingredients in all the ordered pizzas in the past 6 months

--==================================================================================*/


--I determine the date of the last order in the "Orders" table. This declaration is 
--created to not depend on setting the last one date, whatever it may be.

DECLARE @LastMonth DATETIME
SET @LastMonth = DATEADD(month, DATEDIFF(month, 0, (SELECT MAX(order_time) FROM dbo.Orders)), 0)


SELECT l.name as Ingredients_New_Pizza
FROM	
		--4. Subquery: The five most used ingredients in the last 
		--six months was counted and a new pizza was created.
		
		(SELECT TOP 5 fin.name, count(fin.name) as Total
		FROM

			--3. Subquery: Each ingredient was assinged its real name.
			(SELECT num.name as Pizza_name,num.ingredient, ing.name
			 FROM dbo.Ingredients ing,

				 --2. Subquery: Each pizza on the "Orders" table with the 
				 --ingredients for its preparation was linked. The ingredients 
				 --was separetd into new rows using(",") as the separation character.
				 
				 (SELECT name,value ingredient 
				  FROM 

					  --1. Subquery: The orders was selected for the last six months.
					  
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
		ORDER BY Total DESC) l  ;
		--4. END  


/*====================================================================================
--==================   EXCERSICE 2 ===================================================

Help the cook by generating an alphabetically ordered comma separated ingredient list 
for each ordered pizza and add a 2x in front of any ingredient that is requested as 
extra and is present in the standard recipe too. 
For example: 
The recipe for order_id = 5 would be: "2xBacon, BBQ Sauce, Beef, Cheese, Chicken, 
 
--==================================================================================*/

--------------------------
-- ## Function: A more flexible function was created to separate the strings.

CREATE FUNCTION dbo.SplitString 
    (@str NVARCHAR(4000), 
     @separator CHAR(1) )
    
	RETURNS TABLE AS
    RETURN (
        WITH tokens(p, a, b) AS (
            SELECT 1, 1, charindex(@separator, @str)
            UNION all
            SELECT p + 1, b + 1, 
                charindex(@separator, @str, b + 1)
            FROM tokens
            WHERE b > 0
        )
        SELECT p-1 zeroBasedOccurance,
            SUBSTRING(@str, a, 
					  CASE WHEN b > 0 THEN b-a ELSE 4000 END) AS string
        FROM tokens
      );

-----------------
-- ## Part 1: A temporal table was created to make the query cleaner.
SELECT *
INTO  Temp
FROM 		
			--3. Subquery: New table with more information.
			(SELECT num.name as Pizza_name,num.ingredient, ing.name, num.order_id,pizza_order,exclusions,extras
			 FROM dbo.Ingredients ing,

							 --2. Subquery: The ingredients 
							 --was separetd into new rows using(",") as the separation character.
							 (SELECT name,value ingredient ,sel.order_id,pizza_order,exclusions,extras
							  FROM 

								  --1. Subquery: Was added to each "order_id" an identifier of the pizzas that were requested.

								  (SELECT order_id,ord.exclusions,ord.extras,piz.name, ord.order_time, piz.ingredients,
								  IIF(order_id = LEAD(order_id) OVER(ORDER BY order_id), 2, order_id/order_id) 'pizza_order'
								  FROM dbo.Orders ord, dbo.Pizza piz
								  WHERE piz.id = ord.Pizza_id
								 ) sel 
								  --1. END
								  CROSS APPLY STRING_SPLIT(sel.ingredients, ',')) num
							 --2. END
			WHERE ing.id = num.ingredient) AS FINAL ;
			--3. END


-----------------
-- ## Part 2: an alphabetically ordered comma separated ingredient list 
--    was created for each ordered pizza.
SELECT 
  order_id, pizza_order,Pizza_name,
  STUFF((
    
	--2. Subquery: The ingredients of each pizza were joined. The comma was transferred as a union character.

	SELECT ', ' + CAST(	(CASE 
							WHEN ini.ingredient IN 
											--1.1. Subquery: A 2x was added in front of any ingredient that was requested as 
										    --extra
											(SELECT CASE WHEN ISNUMERIC(string) = 1 THEN CAST(string AS INT) else NULL  END
											 FROM dbo.SplitString(ISNULL(ini.exclusions,''), ', ') )
											--1.1. END
								THEN ''
							WHEN ini.ingredient IN
											--1.2. Subquery: The exclusion was removed from ingredients.
											(SELECT CASE WHEN ISNUMERIC(string) = 1 THEN CAST(string AS INT) else NULL  END 
											 FROM dbo.SplitString(ISNULL(ini.extras,''), ',') )
											--1.2. END
								THEN '2x' + name
							ELSE name END) AS VARCHAR(MAX)		) 
    
	FROM dbo.Temp ini
    WHERE (ini.order_id = Results.order_id) AND 
	      (ini.pizza_order = Results.pizza_order) AND 
		  (ini.ingredient NOT IN (ISNULL(ini.exclusions,'')) ) 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS ingredients
    --2. END

FROM  dbo.Temp	Results
GROUP BY order_id, pizza_order, Pizza_name

-----------------
-- ## Part 3:
-- 	  Delete temporal table and function
DROP TABLE dbo.Temp
DROP FUNCTION dbo.SplitString

