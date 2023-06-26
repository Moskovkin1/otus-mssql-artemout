/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


select * from (
select distinct
replace (SUBSTRING( CustomerName,16,30),')','') as CustomerName,
b.OrderID,
convert(varchar,(DATEFROMPARTS(year(b.InvoiceDate),month(b.InvoiceDate),1)),103+'01') InvoiceDate
from sales.Customers a
join [Sales].[Invoices] b on a.CustomerID=b.CustomerID
where a.CustomerID between 2 and 6) b
PIVOT
(
	count([OrderID])
	FOR [CustomerName] 
	IN 
	(
		 [Sylvanite, MT]
		,[Peeples Valley, AZ]
		,[Medicine Lodge, KS]
		,[Gasport, NY]
		,[Jessie, ND]
	)
) AS piv




/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select CustomerName,
pvl.adres_All  from (
select 
CustomerName,
DeliveryAddressLine1,
DeliveryAddressLine2,
PostalAddressLine1,
PostalAddressLine2
from sales.Customers
where CustomerName like '%Tailspin Toys%') b
unpivot
([adres_All] for type_adress in ([DeliveryAddressLine1],[DeliveryAddressLine2],[PostalAddressLine1],[PostalAddressLine2])
) pvl


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select 
CountryID,
CountryName,
c.code_out
from application.Countries  a
	OUTER APPLY
(select IsoAlpha3Code as code_out from application.Countries  b
where a.CountryID=b.CountryID
union 
select convert(varchar,IsoNumericCode)  as code_out from application.Countries  b
where a.CountryID=b.CountryID) c



/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
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

