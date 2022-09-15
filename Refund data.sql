-- Refund data

DECLARE @StartDate date ='2022-04-14 00:00 +6:00'
DECLARE @EndDate date ='2022-04-21 00:00 +6:00'
select COUNT(distinct r.CustomerID) RefundCustomer, SUM(r.Amount) RefundAmount
from ((
	-- BkashPayment
	Select r.RefundEventId,r.Amount,r.Status,
	cast(dbo.tobdt(r.CreatedOn) as date) CreatedDate,
	cast(dbo.tobdt(r.CompletedOn) as date) CompletedOn,c.id CustomerID
	from payment.Refund r 
	join Payment.BkashPayment bp on bp.id=r.BkashPaymentId
	join customer c on c.CustomerGuid=bp.CreditAccount
	where CompletedOn is not null
	and r.CompletedOn>= @StartDate
	and r.CompletedOn< @EndDate
) UNION (
	-- BraintreePayment
	Select r.RefundEventId,r.Amount,r.Status,
	cast(dbo.tobdt(r.CreatedOn) as date) CreatedDate,
	cast(dbo.tobdt(r.CompletedOn) as date) CompletedOn,c.id CustomerID
	from payment.Refund r 
	join Payment.BraintreePayment bp on bp.id=r.BraintreePaymentId
	join customer c on c.CustomerGuid=bp.CreditAccount
	where CompletedOn is not null
	and r.CompletedOn>= @StartDate
	and r.CompletedOn< @EndDate
) UNION (
	-- PortwalletPayment
	Select r.RefundEventId,r.Amount,r.Status,
	cast(dbo.tobdt(r.CreatedOn) as date) CreatedDate,
	cast(dbo.tobdt(r.CompletedOn) as date) CompletedOn,c.id CustomerID
	from payment.Refund r 
	join Payment.PortwalletPayment bp on bp.id=r.PortwalletPaymentId
	join customer c on c.CustomerGuid=bp.CreditAccount
	where CompletedOn is not null
	and r.CompletedOn>= @StartDate
	and r.CompletedOn< @EndDate
)) r