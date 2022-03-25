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

--------------------------
-- ## Function

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
-- ## Part 1
SELECT *
INTO  Temp
FROM 
			(SELECT num.name as Pizza_name,num.ingredient, ing.name, num.order_id,pizza_order,exclusions,extras
			 FROM dbo.Ingredients ing,

							 -- Subquery: 
							 (SELECT name,value ingredient ,sel.order_id,pizza_order,exclusions,extras
							  FROM 

								  --Subquery:
								  (SELECT order_id,ord.exclusions,ord.extras,piz.name, ord.order_time, piz.ingredients,
								  IIF(order_id = LEAD(order_id) OVER(ORDER BY order_id), 2, order_id/order_id) 'pizza_order'
								  FROM dbo.Orders ord, dbo.Pizza piz
								  WHERE piz.id = ord.Pizza_id
								 ) sel 
								  --
								  CROSS APPLY STRING_SPLIT(sel.ingredients, ',')) num
							 --
			WHERE ing.id = num.ingredient) AS FINAL ;


-----------------
-- ## Part 2
SELECT 
  order_id, pizza_order,Pizza_name,
  STUFF((
    
	--Subquery:
	SELECT ', ' + CAST(	(CASE 
							WHEN ini.ingredient IN 
											--Subquery:
											(SELECT CASE WHEN ISNUMERIC(string) = 1 THEN CAST(string AS INT) else NULL  END
											 FROM dbo.SplitString(ISNULL(ini.exclusions,''), ', ') )
								THEN ''
							WHEN ini.ingredient IN
											--Subquery:
											(SELECT CASE WHEN ISNUMERIC(string) = 1 THEN CAST(string AS INT) else NULL  END 
											 FROM dbo.SplitString(ISNULL(ini.extras,''), ',') )
											--
								THEN '2x' + name
							ELSE name END) AS VARCHAR(MAX)		) 
    
	FROM dbo.Temp ini
    WHERE (ini.order_id = Results.order_id) AND 
	      (ini.pizza_order = Results.pizza_order) AND 
		  (ini.ingredient NOT IN (ISNULL(ini.exclusions,'')) ) 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS ingredients
    --

FROM  dbo.Temp	Results
GROUP BY order_id, pizza_order, Pizza_name


-- Delete temporal table and function
DROP TABLE dbo.Temp
DROP FUNCTION dbo.SplitString

