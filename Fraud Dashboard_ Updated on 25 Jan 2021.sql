-- Coupon Abuse

select count(distinct o.customerid) [CustomerCount],
	   count(distinct s.orderid)    [OrderCount],
	   sum(tr.saleprice)            [Saleprice]

from ThingRequest tr
join shipment s on s.id=tr.shipmentid
join [order] o on o.id=s.orderid
where tr.ProductVariantCouponId is not null
and s.ReconciledOn is not null
and IsReturned=0
and IsCancelled=0
and HasFailedBeforeDispatch=0
and IsMissingAfterDispatch=0
and s.ShipmentStatus not in (1,9,10)
and s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'

having count(*)>2


--Telesales Order Details

select sum(OrderAmount)                                     [TotalOrderAmount],
SUM(ReturnedAmount)                                         [ReturnedAmount],
sum(case when o.OrderStatus=40 then OrderAmount else 0 end) [CancelledOrderAmount]

from [order] o
join (select s.orderid,sum(tr.saleprice) OrderAmount from ThingRequest tr join shipment s on s.id=tr.ShipmentId group by s.orderid) oa on oa.Orderid=o.id
left join (select s.orderid,sum(tr.saleprice) ReturnedAmount from ThingRequest tr join shipment s on s.id=tr.ShipmentId where IsReturned=1 group by s.orderid) rt on rt.Orderid=o.id
join (select s.orderid, sum(deliveryfee) DeliveryFee from shipment s group by s.orderid) df on df.OrderId=o.id
join (select orderid ORDERID
from ordernote ont
join employee e on e.id=ont.ActionByCustomerId
where e.DesignationId in (18,65,125)
and ont.note like '%order placed by an admin%'
group by orderid) nt on nt.orderid=o.id
where 
cast(dbo.tobdt(o.createdonutc) as date)>='2022-04-14'
and cast(dbo.tobdt(o.createdonutc) as date)<'2022-04-21'
order by 1 asc 


-- Gift From Chaldal Abuse

select count(*) [Total Order Count]
from (
	select o.Id OrderId, count(*) TotalQuantity
	from ThingRequest tr
	join shipment s on s.id=tr.shipmentid
	join productvariant pv on pv.id=tr.ProductVariantId
	join [order] o on o.id=s.orderid
	where s.ReconciledOn is not null
	and pv.name like '%gift from chaldal%'
	and IsReturned=0
	and IsCancelled=0
	and HasFailedBeforeDispatch=0
	and IsMissingAfterDispatch=0
	and s.ShipmentStatus not in (1,9,10)
	and s.reconciledon>='2022-04-14 00:00 +6:00'
	and s.reconciledon<'2022-04-21 00:00 +6:00'
	group by o.Id
	having count(*)>2
	) t1

-- Iscancelled

Select Count(*) 										  [ReconciledProductQuantity],
sum(case when IsCancelled=1 then 1 else 0 end)            [IsCancelledQuantity],
sum(case when IsCancelled=1 then tr.saleprice else 0 end) [IsCancelledAmount]

from ThingRequest tr
join shipment s on s.id=tr.ShipmentId
where s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'
and s.ShipmentStatus not in (1,9,10)
and s.Reconciledon is not null
order by 1 asc


-- IsReturned

Select Count(*) ReconciledProductQuantity,
sum(case when isreturned=1 then 1 else 0 end) ReturnedQuantity,
sum(case when isreturned=1 then tr.saleprice else 0 end) ReturnedAmount
from ThingRequest tr
join shipment s on s.id=tr.ShipmentId
where s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'
and s.ShipmentStatus not in (1,9,10)
and s.Reconciledon is not null
order by 1 asc


-- 30% Returned on Order (Order Count)

Select cast(dbo.tobdt(reconciledon) as date) ReconciledDate,
s.orderid,
Count(*) ReconciledProductQuantity, sum(tr.saleprice) Saleprice,
sum(case when IsReturned=1 then 1 else 0 end) IsReturnedQuantity,
sum(case when IsReturned=1 then tr.saleprice else 0 end) IsReturnedAmount
from ThingRequest tr
join shipment s on s.id=tr.ShipmentId
where s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'
and s.ShipmentStatus not in (1,9,10)
and s.Reconciledon is not null
group by cast(dbo.tobdt(reconciledon) as date),s.orderid
order by 5 desc

-- Order Details (Delivery Fee 0)

Select count(distinct a.OrderID) OrderCount,
count(distinct a.CustomerId) CustomerCount
from (
Select s.orderid OrderID, o.customerid, sum(deliveryfee) Deliveryfee
from shipment s
join [order] o on o.id=s.orderid
where s.reconciledon is not null
and s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'
and s.shipmentstatus=8
group by s.orderid,o.CustomerId
having sum(deliveryfee)=0) a


-- 0 Delivery Fee (Repeated Customers)

Select count(*) RepeatedCustomerCount
from (
Select a.Customerid,count(distinct a.OrderID) OrderCount
from (
Select o.customerid Customerid,o.id OrderID,sum(deliveryfee) DeliveryFee
from shipment s
join [order] o on o.id=s.orderid
where s.reconciledon is not null
and s.reconciledon>='2022-04-14 00:00 +6:00'
and s.reconciledon<'2022-04-21 00:00 +6:00'
and s.shipmentstatus=8
group by o.CustomerId,o.id
having sum(deliveryfee)=0 ) a
group by a.Customerid
having count(distinct a.orderid)>1)b

-- Organizational Data (Without Accounts Department)

select COUNT(distinct c2.id) CustomerID, SUM(t.MoneyBalance) MoneyBalance
from accounting.txn t
join accounting.account ac2 on ac2.id = t.accountid
join accounting.event ev on ev.id = t.eventid
join customer c2 on c2.CustomerGuid = ac2.[owner] and ac2.AccountHead = 'Organizational'
inner join
(select c.id as id, max(sequencenum) as seq from accounting.txn t
join accounting.account ac on ac.id = t.accountid
join accounting.event ev on ev.id = t.eventid
join customer c on c.CustomerGuid = ac.[owner]
join employee e on e.id=c.id
where [When]>='2022-04-14 00:00 +6:00'
and [When]<'2022-04-21 00:00 +6:00'
and accounthead = 'Organizational'
and e.DepartmentTypeId not in (5)
group by c.id) b on c2.id = b.id and t.sequencenum = b.seq
where t.MoneyBalance<>0
order by 2 asc


-- Conveyance Data

select SUM(dt.Amount) Conveyance
from (
	select  Cast(dbo.tobdt([When]) as DATE) Dates, Amount, Memo,
	substring(memo,(PATINDEX('% [0-9]%',Memo)),3) Warehouses
	from accounting.txn t
	join accounting.account ac on ac.id = t.accountid
	join accounting.event ev on ev.id = t.eventid
	where [When]>= '2022-04-14 00:00 +6:00'
	and [When]<'2022-04-21 00:00 +6:00'
	and Memo LIKE '%conveyance%'
	and MEMO like '%Expense%'
) dt
where dt.Amount > 0

-- Vendor Wise Fulfilment

select cast(dbo.tobdt(po.CompletedOn) as date) Dates,
v.id vendorid,v.name, po.id POID,
count(*) RequestedQuantity,
sum(case when t.costprice is not null then 1 else 0 end) ReceivedQuantity,
sum(case when t.costprice is not null then t.costprice else 0 end) ReceivedAmount
from thing t
join purchaseorder po on po.id=t.purchaseorderid
join vendor v on v.id=po.vendorid
where
po.CompletedOn>='2022-04-14 00:00 +6:00'
and po.CompletedOn<'2022-04-21 00:00 +6:00'
and po.purchaseorderstatusid not in (3)
and po.CompletedOn is not null
group by v.id,v.name, po.id,cast(dbo.tobdt(po.CompletedOn) as date)
order by 1 asc


-- Snag_Damage

select COUNT(distinct customerid) DamageCustomer, sum(saleprice) DamageAmount
from ThingRequest tr
join shipment s on s.id = tr.shipmentid
join [order] o on o.id = s.orderid
where ReconciledOn>='2022-04-14 00:00 +6:00'
and ReconciledOn<'2022-04-21 00:00 +6:00'
and ReconciledOn is NOT NULL
and SnagType=3


-- Snag_Missing

select COUNT(distinct customerid) MissingCustomer, sum(saleprice) MissingAmount
from ThingRequest tr
join shipment s on s.id = tr.shipmentid
join [order] o on o.id = s.orderid
where ReconciledOn>='2022-04-14 00:00 +6:00'
and ReconciledOn<'2022-04-21 00:00 +6:00'
and ReconciledOn is NOT NULL
and SnagType=1


