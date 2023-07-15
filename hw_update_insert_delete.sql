/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
---создаем копию витрины [Sales].[Customers] top 10 записей
drop table if exists Sales.Customers_copy
select top 10
CustomerID,
CustomerName,
BillToCustomerID,
CustomerCategoryID,
BuyingGroupID
into Sales.Customers_copy from [Sales].[Customers]

-- добавляем новые записи (выбрал только 5 полей для примера)
insert into Sales.Customers_copy 
(CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,BuyingGroupID)
select
CustomerID,
CustomerName,
BillToCustomerID,
CustomerCategoryID,
BuyingGroupID
from [Sales].[Customers]
where CustomerID between 11 and 15

select * from Sales.Customers_copy --- проверка результата

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete Sales.Customers_copy
where CustomerID=15

select * from Sales.Customers_copy

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update Sales.Customers_copy
set CustomerName='ARTEM MOSKOVKIN'
where CustomerID=14;

select * from Sales.Customers_copy

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

---подготовим витринку из которой будем инсертить и апдейтить
drop table if exists customer_original
select
CustomerID,
CustomerName,
BillToCustomerID,
CustomerCategoryID,
BuyingGroupID
into customer_original
from [Sales].[Customers]
where CustomerID between 13 and 16


merge Sales.Customers_copy as c
using customer_original as original
on (c.customerID=original.customerID)
when matched then update set 
							c.CustomerID					=original.CustomerID,
							c.CustomerName					=original.CustomerName,
							c.BillToCustomerID				=original.BillToCustomerID,
							c.CustomerCategoryID			=original.CustomerCategoryID,
							c.BuyingGroupID					=original.BuyingGroupID
WHEN NOT MATCHED THEN INSERT VALUES (
							original.CustomerID,
							original.CustomerName,
							original.BillToCustomerID,
							original.CustomerCategoryID,
							original.BuyingGroupID
									)
OUTPUT $action, inserted.*;
		
--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert


exec sp_configure 'show advanced options', 1;
go
reconfigure;
go
exec sp_configure 'xp_cmdshell', 1;
go
reconfigure;
go

select @@SERVERNAME  --ARTEM

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.InvoiceLines" out   "D:\sql\InvoiceLines.txt" -T -w -t"!QAZ1qaz" -S ARTEM'

drop table if exists Sales.InvoiceLinesHW08
CREATE TABLE [Sales].[InvoiceLinesHW08](
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_InvoiceLinesHW08] PRIMARY KEY CLUSTERED 
(
	[InvoiceLineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [USERDATA]
) ON [USERDATA]
GO

bulk insert Sales.InvoiceLinesHW08
from "D:\sql\InvoiceLines.txt"
with (
	batchsize = 999,
	datafiletype = 'widechar',
	fieldterminator = '!QAZ1qaz',
	rowterminator = '\n',
	keepnulls,
	tablock);

select * from Sales.InvoiceLinesHW08
