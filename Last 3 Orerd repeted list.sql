SET NOCOUNT ON
DECLARE @RunTime int;
DECLARE @SnagType int = 3 -- SnagType = 1 Missing || SnagType = 3 Damage
DECLARE @StartDate Date ='2022-04-14 00:00 +6:00';
DECLARE @EndDate Date ='2022-04-21 00:00 +6:00';
DECLARE @CustomerIds TABLE ( ID int IDENTITY(1, 1) PRIMARY KEY, CustomerID int );
DECLARE @LastThreeOrderID TABLE ( ID int IDENTITY(1, 1) PRIMARY KEY, CustomerID int , OrderID int);
DECLARE @SnagMDLastThreeOrderID TABLE ( ID int IDENTITY(1, 1) PRIMARY KEY, CustomerID int , OrderID int, Amount int);


-- Get Ordered Customer Ids
INSERT INTO @CustomerIds 
select o.CustomerId
from [Order] o
where CAST(dbo.ToBdt(o.CreatedOnUtc) AS DATE) >= @StartDate
and CAST(dbo.ToBdt(o.CreatedOnUtc) AS DATE) < @EndDate
and o.OrderStatus in (30)
group by o.CustomerId

-- Get Last 3 OrderIds
select @RunTime = count(ID) from @CustomerIds;
WHILE @RunTime >= 1
BEGIN

	INSERT INTO @LastThreeOrderID 
	select top 3 o.CustomerId, o.Id OrderID
	from [Order] o
	where o.OrderStatus in (30)
	and o.CustomerId = (select CustomerID from @CustomerIds where ID = @RunTime)
	order by 2 desc

SET @RunTime = @RunTime-1;
END

--select * from @LastThreeOrderID


-- Snag_Missing_Damage
INSERT INTO @SnagMDLastThreeOrderID
select customerid CustomerID, o.Id OrderID, sum(saleprice) Amount
from ThingRequest tr
join shipment s on s.id = tr.shipmentid
join [order] o on o.id = s.orderid
where SnagType = @SnagType
and o.Id in (select OrderID from @LastThreeOrderID)
group by customerid, o.Id

--select * from @SnagMDLastThreeOrderID

--SnagRepetedCustomer last 3 order Checking
select count(*) SnagRepetedCustomerCount
from (
	select so.CustomerID, COUNT(so.CustomerID) SnagRepetedCustomer
	from @SnagMDLastThreeOrderID so
	group by so.CustomerID 
	having COUNT(so.CustomerID) = 3
) dt




