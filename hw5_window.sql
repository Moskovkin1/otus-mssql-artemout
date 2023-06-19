/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on

;with cte as (
	select 
	a.InvoiceID,
	a.InvoiceDate,
	c.CustomerName,
	month(a.InvoiceDate) InvoiceDate_month,
	YEAR (a.InvoiceDate)InvoiceDate_YEAR,
	sum(b.TransactionAmount) TransactionAmount2
	from sales.invoices a
		join sales.customertransactions b on a.InvoiceID=b.InvoiceID
		join sales.customers c on a.CustomerID=c.CustomerID
	where InvoiceDate >= '2015-01-01'
	group by a.InvoiceID,a.InvoiceDate,c.CustomerName,month(a.InvoiceDate),YEAR (a.InvoiceDate)) 
			select cte.InvoiceID,cte.CustomerName,cte.InvoiceDate,cte.TransactionAmount2 as 'сумма продажи',
			sum(b.TransactionAmount2) as 'накопленный итог по месяцам'
			from cte
				left join (
				select 
				month(a.InvoiceDate) InvoiceDate_month,
				YEAR (a.InvoiceDate)InvoiceDate_YEAR,
				sum(b.TransactionAmount) TransactionAmount2
				from sales.invoices a
				join sales.customertransactions b on a.InvoiceID=b.InvoiceID
				where InvoiceDate >= '2015-01-01'
				group by YEAR (a.InvoiceDate), month(a.InvoiceDate) ) b 
				on (cte.InvoiceDate_month>=b.InvoiceDate_month and cte.InvoiceDate_YEAR=b.InvoiceDate_YEAR)
				    or cte.InvoiceDate_YEAR>b.InvoiceDate_YEAR
					group by cte.InvoiceID,cte.InvoiceDate,cte.CustomerName,CTE.InvoiceDate_YEAR,cte.InvoiceDate_month,cte.TransactionAmount2
	order by CTE.InvoiceDate_YEAR,CTE.InvoiceDate_month
/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select 
	a.InvoiceID,
	a.InvoiceDate,
	c.CustomerName,
	(b.TransactionAmount) TransactionAmount,
	sum(TransactionAmount) over (order by  year(a.InvoiceDate),month(a.InvoiceDate) ) as 'total_sum'
	from sales.invoices a
		join sales.customertransactions b on a.InvoiceID=b.InvoiceID
		join sales.customers c on a.CustomerID=c.CustomerID 
	where InvoiceDate>='2015-01-01'
	group by a.InvoiceID,
	a.InvoiceDate,
	c.CustomerName,
	month(a.InvoiceDate) ,
	YEAR (a.InvoiceDate),
	b.TransactionAmount

	--ВЫВОД
	--если сравнить расчет накопленного итога с оконной функцией и без через set statistics time, io on
	--то получается с оконной функцией расчет происходит почти в два раза быстрее и писать его проще=)


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select * from (
	select 
	StockItemName,
	Quantity,
	row_number() over (partition by TransactionDate_month order by Quantity desc) as row_quality,
	TransactionDate_month 
from (
select distinct
StockItemName,
SUM(Quantity) OVER (PARTITION BY month(TransactionDate), StockItemName)  Quantity,
month(TransactionDate) TransactionDate_month
from Sales.InvoiceLines si --- кол-во товаров
	join Sales.CustomerTransactions sc on si.InvoiceID=sc.InvoiceID --дата продажи
	join Warehouse.StockItems ws on ws.StockItemID=si.StockItemID  --- название товара 
where TransactionDate between '2016-01-01' and '2016-12-31') tbl1
) tbl2
where row_quality<=2
order by TransactionDate_month asc,Quantity desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
---пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново


Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
row_number() OVER (PARTITION BY left(StockItemName, 1) ORDER BY StockItemName ASC) number_item_name,
StockItemName
FROM Warehouse.StockItems;


--посчитайте общее количество товаров и выведете полем в этом же запросе
Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
row_number() OVER (PARTITION BY left(StockItemName, 1) ORDER BY StockItemName ASC) number_item_name,
StockItemName,
sum (QuantityPerOuter) over (partition by StockItemName) QuantityPerOuter
FROM Warehouse.StockItems

--посчитайте общее количество товаров в зависимости от первой буквы названия товара
Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
StockItemName,
sum (QuantityPerOuter) over (partition by left(StockItemName,1) order by left( StockItemName,1) asc) QuantityPerOuter
FROM Warehouse.StockItems

--отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
StockItemName, 
lead(StockItemID) over (order by StockItemName desc) lead_StockItemID
FROM Warehouse.StockItems

--предыдущий ид товара с тем же порядком отображения (по имени)
Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
StockItemName, 
lag(StockItemID) over (order by StockItemName desc) lag_StockItemID
FROM Warehouse.StockItems

---названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
StockItemName, 
isnull(lag(StockItemName,2) over (order by StockItemName),'No items') lag_StockItemID
FROM Warehouse.StockItems


--сформируйте 30 групп товаров по полю вес товара на 1 шт

Select
StockItemID,
unitprice,
isnull(brand,0) as brand,
StockItemName, 
ntile(30) over (order by TypicalWeightPerUnit) as ГК
FROM Warehouse.StockItems



/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.

*/

;with cte as (
	select distinct
	o.SalespersonPersonID,
	p.FullName,
	max(c.CustomerTransactionID) over (partition by o.SalespersonPersonID) CustomerTransactionID
	FROM  Application.People p
		join Sales.Orders o on o.SalespersonPersonID=p.PersonID
		join Sales.Invoices b ON o.OrderID = b.OrderID
		join Sales.CustomerTransactions c on b.InvoiceID=c.InvoiceID
		)
select distinct
cte.SalespersonPersonID,
FullName,
g.CustomerID,
g.CustomerName,
c.TransactionDate,
c.TransactionAmount
from cte
	join Sales.CustomerTransactions c on cte.CustomerTransactionID=c.CustomerTransactionID
	join Sales.Invoices b ON c.InvoiceID = b.InvoiceID
	join  Sales.Customers g on g.CustomerID=b.CustomerID
order by cte.SalespersonPersonID


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select 
CustomerID,
CustomerName,
StockItemID,
UnitPrice,
TransactionDate_max
from (
	select distinct
	b.CustomerID,
	c.CustomerName,
	StockItemID,
	a.UnitPrice,
	max(g.TransactionDate) over (partition by c.CustomerID,a.StockItemID) as TransactionDate_max,
	dense_rank() OVER (PARTITION BY c.CustomerID ORDER BY a.UnitPrice DESC) AS Rank_customer_price
	from sales.OrderLines a
	join Sales.Invoices b on b.OrderID=a.OrderID
	join Sales.Customers c on c.CustomerID=b.CustomerID
	join Sales.CustomerTransactions g on g.InvoiceID=b.InvoiceID) tbl1
where Rank_customer_price<=2
order by CustomerID asc,UnitPrice desc
