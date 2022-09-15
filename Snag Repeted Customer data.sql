DECLARE @EndDate date ='2022-04-21  00:00 +6:00'
DECLARE @SnagType int = 1 -- Snag Damage = 3 || Missing = 1

select COUNT(distinct preWeek.DamageCustomer) Snag_Customer_Repeated
from (select pdt.DamageCustomer, COUNT(pdt.DamageCustomer) Damage
	from ((
		select customerid DamageCustomer, sum(saleprice) DamageAmount
		from ThingRequest tr
		join shipment s on s.id = tr.shipmentid
		join [order] o on o.id = s.orderid
		where ReconciledOn>= CONVERT(DATE,(dateadd(day,-14,@EndDate)))
		and ReconciledOn< CONVERT(DATE,(dateadd(day,-7,@EndDate)))
		and ReconciledOn is NOT NULL
		and SnagType=@SnagType
		group by customerid
	) UNION (
		select customerid DamageCustomer, sum(saleprice) DamageAmount
		from ThingRequest tr
		join shipment s on s.id = tr.shipmentid
		join [order] o on o.id = s.orderid
		where ReconciledOn>= CONVERT(DATE,(dateadd(day,-21,@EndDate)))
		and ReconciledOn< CONVERT(DATE,(dateadd(day,-14,@EndDate)))
		and ReconciledOn is NOT NULL
		and SnagType=@SnagType
		group by customerid
	) UNION (
		select customerid DamageCustomer, sum(saleprice) DamageAmount
		from ThingRequest tr
		join shipment s on s.id = tr.shipmentid
		join [order] o on o.id = s.orderid
		where ReconciledOn>= CONVERT(DATE,(dateadd(day,-28,@EndDate)))
		and ReconciledOn< CONVERT(DATE,(dateadd(day,-21,@EndDate)))
		and ReconciledOn is NOT NULL
		and SnagType=@SnagType
		group by customerid
	)) pdt
	group by pdt.DamageCustomer
	having COUNT(pdt.DamageCustomer) = 3
) last3week
join (
	select customerid DamageCustomer, sum(saleprice) DamageAmount
	from ThingRequest tr
	join shipment s on s.id = tr.shipmentid
	join [order] o on o.id = s.orderid
	where ReconciledOn>= CONVERT(DATE,(dateadd(day,-7,@EndDate)))
	and ReconciledOn< @EndDate
	and ReconciledOn is NOT NULL
	and SnagType=@SnagType
	group by customerid
) preWeek on preWeek.DamageCustomer = last3week.DamageCustomer
