--1.�������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
--� �� ������� �� ����� ������� 04 ���� 2015 ����. ������� �� ���������� � ��� ������ ���. ������� �������� � ������� Sales.Invoices.

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

--2.�������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. �������: �� ������, ������������ ������, ����.

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

--3.�������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� �� Sales.CustomerTransactions. 
--����������� ��������� �������� (� ��� ����� � CTE).

--������� 1 (�����������)

select distinct top 5 
CustomerTransactionID,
CustomerID,
TransactionAmount 
from Sales.CustomerTransactions
order by TransactionAmount desc

--������� 2 ����� cte
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

--������� 3 � ����������� 
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

--4.�������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������, 
--� ����� ��� ����������, ������� ����������� �������� ������� (PackedByPersonID).


--������� � �����������

select distinct
CityID,
CityName,
FullName
from Application.Cities  cities --- ������
join sales.Customers b on b.DeliveryCityID=cities.CityID -- ������� ����� � ����������� � ���������
join sales.Invoices invoice on invoice.CustomerID=b.CustomerID --- ����� ������ � ���������� � ��������
join Application.People people on people.PersonID=invoice.PackedByPersonID-- ��� ����������
join Sales.OrderLines stock on stock.OrderID=invoice.OrderID  
join (
select top 3
StockItemID, 
sum(UnitPrice) UnitPrice 
from Warehouse.StockItems 
group by StockItemID
order by UnitPrice desc) price on price.StockItemID=stock.StockItemID

--������� � cte � �����������
;with cte as (select distinct
CityID,
CityName,
FullName,
StockItemID
from  Application.Cities
	join sales.Customers b on b.DeliveryCityID=cities.CityID -- ������� ����� � ����������� � ���������
	join sales.Invoices invoice on invoice.CustomerID=b.CustomerID --- ����� ������ � ���������� � ��������
	join Application.People people on people.PersonID=invoice.PackedByPersonID-- ��� ����������
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