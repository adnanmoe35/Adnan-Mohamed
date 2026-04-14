/*
Project: Sales Data Analysis using SQL

Dataset: WideWorldImporters DW (Data Warehouse) & WorldWideImporters

Description:
This project analyzes sales, customer behavior, and product performance using SQL. 
The goal is to extract insights that support business decisions such as identifying 
high-value customers, evaluating employee performance, and analyzing product trends.

Key Analysis:
- Identified customers with changing purchasing patterns over time
- Filtered employees based on product involvement using subqueries
- Analyzed product sales and categorized attributes (e.g., color coding)
- Evaluated employee performance based on total profit
- Applied business rules such as discounts based on region and revenue thresholds

Skills Demonstrated:
- SQL Joins (INNER JOIN)
- Aggregations (SUM, COUNT)
- Filtering (WHERE, HAVING)
- Subqueries (NOT EXISTS)
- CASE statements for business logic
- Data transformation and analysis
*/

/* ---------------------------------------------------------------------------------------------------
-- Display a full listing of all order detail records.
-- Contribution: I counted how many purchase orders each customer made 
in two different date ranges using subqueries, then filtered the results so only customers with 
fewer than 30 orders in late 2013 and more than 25 orders in early 2014 were returned. 
The final list is sorted alphabetically by customer name.
*/ -----------------------------------------------------------------------------------------------------

SELECT C.CustomerName
FROM Sales.Customers AS C
INNER JOIN Sales.Orders AS SO ON C.CustomerID = SO.CustomerID
GROUP BY C.CustomerName
HAVING 
COUNT(CASE
              WHEN SO.OrderDate >= '2013-10-01' AND SO.OrderDate <= '2013-12-31'
              THEN 1
         END) < 30 AND
COUNT(CASE
              WHEN SO.OrderDate >= '2014-01-01' AND SO.OrderDate <= '2014-06-30'
              THEN 1
         END) > 25
ORDER BY C.CustomerName

/* ---------------------------------------------------------------------------------------------------
-- Show the names of the salespersons (Employee) in descending
   order who were NOT involved in selling ANY toy or chocolate
   items. 
-- Contribution: I selected all employees and used a NOT IN subquery to remove any 
salesperson who sold toy or chocolate items. This returns only employees who were never involved in selling those product types.
*/ -----------------------------------------------------------------------------------------------------
SELECT DE.Employee
FROM Dimension.Employee AS DE
WHERE NOT EXISTS
(
    SELECT *
    FROM Fact.Sale AS FS
    INNER JOIN Dimension.[Stock Item] AS DSI ON FS.[Stock Item Key] = DSI.[Stock Item Key]
    WHERE FS.[Salesperson Key] = DE.[Employee Key] AND ( DSI.[Stock Item] LIKE '%toy%'
         OR DSI.[Stock Item] LIKE '%chocolate%')
)
ORDER BY DE.Employee DESC

/* ---------------------------------------------------------------------------------------------------
-- For stock items named slippers, jacket, or mug, show:
   - Stock Item
   - color in coded format
   - total quantity sold < 15000
   Sort by quantity sold.
-- Contribution: I filtered stock items to slippers, jackets, and mugs, then grouped sales 
to calculate total quantity sold for each item. I converted each color to a coded label and selected 
only items with total quantities below 15,000, then sorted by quantity sold.
*/ -----------------------------------------------------------------------------------------------------
SELECT DSI.[Stock Item],
    CASE
        WHEN DSI.Color IS NULL OR DSI.Color = '' THEN 'Missing'
        WHEN DSI.Color LIKE '%Blue%' THEN 'BLU'
        WHEN DSI.Color LIKE '%Red%' THEN 'RED'
        WHEN DSI.Color LIKE '%Black%' THEN 'BLK'
        WHEN DSI.Color LIKE '%White%' THEN 'WHT'
        WHEN DSI.Color LIKE '%Gray%' OR DSI.Color LIKE '%Grey%' THEN 'GRY'
        WHEN DSI.Color LIKE '%Brown%' THEN 'BRW'
        WHEN DSI.Color LIKE '%Green%' THEN 'GRN'
        WHEN DSI.Color LIKE '%Yellow%' THEN 'YLW'
        ELSE 'Missing'
    END AS Color,
    SUM(FS.Quantity) AS [Quantity Sold]
FROM Fact.Sale FS
JOIN Dimension.[Stock Item] DSI
    ON FS.[Stock Item Key] = DSI.[Stock Item Key]
WHERE DSI.[Stock Item] LIKE '%slippers%'
   OR DSI.[Stock Item] LIKE '%jacket%'
   OR DSI.[Stock Item] LIKE '%mug%'
GROUP BY DSI.[Stock Item],
    CASE
        WHEN DSI.Color IS NULL OR DSI.Color = '' THEN 'Missing'
        WHEN DSI.Color LIKE '%Blue%' THEN 'BLU'
        WHEN DSI.Color LIKE '%Red%' THEN 'RED'
        WHEN DSI.Color LIKE '%Black%' THEN 'BLK'
        WHEN DSI.Color LIKE '%White%' THEN 'WHT'
        WHEN DSI.Color LIKE '%Gray%' OR DSI.Color LIKE '%Grey%' THEN 'GRY'
        WHEN DSI.Color LIKE '%Brown%' THEN 'BRW'
        WHEN DSI.Color LIKE '%Green%' THEN 'GRN'
        WHEN DSI.Color LIKE '%Yellow%' THEN 'YLW'
        ELSE 'Missing'
    END
HAVING SUM(FS.Quantity) < 15000
ORDER BY [Quantity Sold]

/* ---------------------------------------------------------------------------------------------------
-- Classify employees by total profit:
-- Contribution: I calculated total profit for each employee using Fact.
Sale and assigned a performance category based on profit thresholds. The results are ordered by highest total profit and then by employee name.
*/ -----------------------------------------------------------------------------------------------------

SELECT DE.Employee,
    SUM(FS.Profit) AS TotalProfitAmount,
    CASE
        WHEN SUM(FS.Profit) > 8700000 THEN 'Top Performer'
        WHEN SUM(FS.Profit) BETWEEN 8000000 AND 8700000 THEN 'Average Performer'
        ELSE 'Under Performer'
    END AS PerformanceCategory
FROM Fact.Sale AS FS
JOIN Dimension.Employee AS DE ON FS.[Salesperson Key] = DE.[Employee Key]
GROUP BY DE.Employee
ORDER BY TotalProfitAmount DESC, DE.Employee ASC

/* ---------------------------------------------------------------------------------------------------
-- Orders in CA, TX, MT, IN during Aug and Sep with
   Total Including Tax > 8000.
   Discount rules on the total (after tax) 
-- Contribution: I grouped sales by state and month for August and September, filtered 
totals above $8,000, and applied discount rules based on the state and total amount. 
The output shows original and updated prices sorted by state and descending updated price.
*/ -----------------------------------------------------------------------------------------------------

WITH SALES_BY_STATE_MONTH AS
(
    SELECT CI.[State Province], DD.[Month] AS [Month], 
    SUM(FS.[Total Including Tax]) AS [Total Including Tax]
    FROM Fact.Sale AS FS INNER JOIN Dimension.City AS CI ON FS.[City Key] = CI.[City Key]
    INNER JOIN Dimension.Date AS DD ON FS.[Invoice Date Key] = DD.[Date]   
    WHERE CI.[State Province] IN ('California', 'Texas', 'Montana', 'Indiana')
    AND DD.[Month] IN ('August', 'September')
    GROUP BY CI.[State Province], DD.[Month]                               
)
SELECT [State Province], [Month], [Total Including Tax],
    CASE
        WHEN [State Province] IN ('California', 'Texas')
        AND [Total Including Tax] > 10000 THEN [Total Including Tax] * 0.85
        WHEN [State Province] IN ('Montana', 'Indiana')
        AND [Total Including Tax] > 15000 THEN [Total Including Tax] * 0.90
        ELSE [Total Including Tax]
    END AS [Updated Price]
FROM SALES_BY_STATE_MONTH
WHERE [Total Including Tax] > 8000
ORDER BY [State Province] ASC, [Updated Price] DESC