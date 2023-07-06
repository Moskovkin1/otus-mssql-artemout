/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 





Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--вариант с OPENXML

declare @xml_document xml
select @xml_document=bulkcolumn
from openrowset (bulk 'D:\sql\StockItems-188-1fb5df.xml',single_clob ) as date

--select @xml_document as [@xml_document]

declare @dochandle int 
exec sp_xml_preparedocument @dochandle output,@xml_document

--select @dochandle as dochandle

--помещаем данные в времянку  #xml_ma
drop table if exists #xml_ma
select * 
into #xml_ma
from openxml (@dochandle ,N'/StockItems/Item')
with (
[Name] nvarchar(100),
SupplierID int 'SupplierID',
UnitPackageID int 'Package/UnitPackageID',
OuterPackageID int 'Package/OuterPackageID',
QuantityPerOuter int 'Package/QuantityPerOuter',
TypicalWeightPerUnit decimal 'Package/TypicalWeightPerUnit',
LeadTimeDays int 'LeadTimeDays',
IsChillerStock bit 'IsChillerStock',
TaxRate decimal 'TaxRate',
UnitPrice decimal 'UnitPrice') 

---копируем таблицу Warehouse.StockItems для обновления

drop table if exists #copy_StockItems
select 
StockItemName,
SupplierID,
UnitPackageID,
OuterPackageID,
QuantityPerOuter,
TypicalWeightPerUnit,
LeadTimeDays,
IsChillerStock,
TaxRate,
UnitPrice
into #copy_StockItems
from Warehouse.StockItems

--обновляем таблицу/вставляем записи #copy_StockItems данными из xml
MERGE #copy_StockItems AS copy_StockItems
	USING #xml_ma AS xml_ma
	ON (copy_StockItems.StockItemName = xml_ma.name COLLATE database_default)
	WHEN MATCHED THEN UPDATE SET 
							copy_StockItems.SupplierID				=xml_ma.SupplierID,
							copy_StockItems.UnitPackageID			=xml_ma.UnitPackageID,
							copy_StockItems.OuterPackageID			=xml_ma.OuterPackageID,
							copy_StockItems.QuantityPerOuter		=xml_ma.QuantityPerOuter,	
							copy_StockItems.TypicalWeightPerUnit	=xml_ma.TypicalWeightPerUnit,	
							copy_StockItems.LeadTimeDays			=xml_ma.LeadTimeDays,	
							copy_StockItems.IsChillerStock			=xml_ma.IsChillerStock,
							copy_StockItems.TaxRate					=xml_ma.TaxRate				
		
	WHEN NOT MATCHED THEN INSERT VALUES(
							xml_ma.name,
							xml_ma.SupplierID,
							xml_ma.UnitPackageID,
							xml_ma.OuterPackageID,
							xml_ma.QuantityPerOuter,
							xml_ma.TypicalWeightPerUnit,
							xml_ma.LeadTimeDays,
							xml_ma.IsChillerStock,
							xml_ma.TaxRate,
							xml_ma.UnitPrice)
	OUTPUT $action, inserted.*;


--вариант с XQuery

Declare @xml XML;
Set @xml = (select * from openrowset (bulk 'D:\sql\StockItems-188-1fb5df.xml', single_clob) as d)

select 
	t.Item.value('(@Name)[1]', 'nvarchar(200)')							as StockItemName,
	t.Item.value('(SupplierID)[1]',	'int')								as SupplierID,
	t.Item.value('(Package/UnitPackageID)[1]', 'int')					as UnitPackageID,
	t.Item.value('(Package/OuterPackageID)[1]',	'int')					as OuterPackageID,
	t.Item.value('(Package/QuantityPerOuter)[1]', 'int')				as QuantityPerOuter,
	t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(9,2)')	as TypicalWeightPerUnit,
	t.Item.value('(LeadTimeDays)[1]', 'int')							as LeadTimeDays,
	t.Item.value('(IsChillerStock)[1]', 'int')							as IsChillerStock,
	t.Item.value('(TaxRate)[1]', 'decimal(9,2)')						as TaxRate,
	t.Item.value('(UnitPrice)[1]', 'decimal(9,2)')						as UnitPrice
from @xml.nodes('/StockItems/Item') as t(Item);

---обновлять файл Warehouse.StockItems не стал т к суть такая же


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

Select 
a.StockItemName as [@name],
SupplierID,
(	Select 
	b.UnitPackageID,
	b.OuterPackageID,
	b.QuantityPerOuter,
	b.TypicalWeightPerUnit
	from Warehouse.StockItems b
	where a.StockItemID = b.StockItemID
	FOR XML PATH('Package'), 
	TYPE),
	LeadTimeDays,
	IsChillerStock,
	TaxRate,
	UnitPrice
from Warehouse.StockItems a
Order by [@Name]
FOR XML PATH('Item'), ROOT('StockItems')

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
	 StockItemID
	,StockItemName
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	,JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems




select top 10 * from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

Select
StockItemID,
StockItemName,
CustomFields,
a.value as searchingInTagValue
from Warehouse.StockItems
CROSS APPLY openjson (Warehouse.StockItems.CustomFields,'$.Tags') as a
where a.value = 'Vintage'
