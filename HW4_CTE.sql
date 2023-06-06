--1.Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
--и не сделали ни одной продажи 04 июля 2015 года. Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.

select
personID,
FullName 
from Application.People
where IsSalesPerson =1 and PersonID not in (
select distinct 
SalespersonPersonID
from Sales.Invoices where InvoiceDate = '2015-07-04'
)


;with cte as  (select
personID,
FullName 
from Application.People
where IsSalesPerson =1 and PersonID not in (
select distinct 
SalespersonPersonID
from Sales.Invoices where InvoiceDate = '2015-07-04'
))
select * from cte;

--2.Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.

select 
StockItemID,
StockItemName,
UnitPackageID
from Warehouse.StockItems
where UnitPrice in (select min(unitprice) from Warehouse.StockItems)

select 
StockItemID,
StockItemName,
UnitPackageID
from Warehouse.StockItems
where UnitPrice <= ALL (select unitprice from Warehouse.StockItems)

--3.Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. 
--Представьте несколько способов (в том числе с CTE).

--вариант 1 (првоерочный)

select distinct top 5 
CustomerTransactionID,
CustomerID,
TransactionAmount 
from Sales.CustomerTransactions
order by TransactionAmount desc

--вариант 2 через cte
;with cte2 as (select top 5 CustomerTransactionID,
CustomerID,
TransactionAmount 
from Sales.CustomerTransactions
order by TransactionAmount desc
)
select a.CustomerTransactionID,
a.CustomerID,
a.TransactionAmount 
from Sales.CustomerTransactions a
join cte2 b on a.CustomerTransactionID=b.CustomerTransactionID
order by a.TransactionAmount desc

--вариант 3 с подзапросом 
select 
CustomerTransactionID,
CustomerID,
TransactionAmount 
from Sales.CustomerTransactions
where CustomerTransactionID in (
select top 5 
CustomerTransactionID
from Sales.CustomerTransactions
order by TransactionAmount desc)

--4.Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, 
--а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).


--вариант с подзапросом

select distinct
CityID,
CityName,
FullName
from Application.Cities  cities --- города
join sales.Customers b on b.DeliveryCityID=cities.CityID -- связать город с покупателем и продавцом
join sales.Invoices invoice on invoice.CustomerID=b.CustomerID --- связь товара и покупателя и продавца
join Application.People people on people.PersonID=invoice.PackedByPersonID-- имя сотрудника
join Sales.OrderLines stock on stock.OrderID=invoice.OrderID  
join (
select top 3
StockItemID, 
sum(UnitPrice) UnitPrice 
from Warehouse.StockItems 
group by StockItemID
order by UnitPrice desc) price on price.StockItemID=stock.StockItemID

--вариант с cte и подзапросом
;with cte as (select distinct
CityID,
CityName,
FullName,
StockItemID
from  Application.Cities
	join sales.Customers b on b.DeliveryCityID=cities.CityID -- связать город с покупателем и продавцом
	join sales.Invoices invoice on invoice.CustomerID=b.CustomerID --- связь товара и покупателя и продавца
	join Application.People people on people.PersonID=invoice.PackedByPersonID-- имя сотрудника
	join Sales.OrderLines stock on stock.OrderID=invoice.OrderID )
select  distinct
CityID,
CityName,
FullName
from cte
where StockItemID in (
	select
	StockItemID 
	from (select top 3StockItemID, sum(UnitPrice) UnitPrice from Warehouse.StockItems group by StockItemID order by UnitPrice desc) c )
order by FullName asc