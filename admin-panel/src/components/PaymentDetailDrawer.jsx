import { useEffect, useMemo, useState } from 'react';
import { formatDateTime } from '../utils/format';

function formatAmount(paise, currency = 'INR') {
  const normalized = Number.parseInt(paise, 10);
  if (!Number.isFinite(normalized)) return '-';
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency,
    maximumFractionDigits: 2,
  }).format(normalized / 100);
}

function KeyValue({ label, children }) {
  return (
    <div className="kv">
      <span className="kv-label">{label}</span>
      <span className="kv-value">{children ?? '—'}</span>
    </div>
  );
}

export function PaymentDetailDrawer({ record, adminEmail, onClose, onRefund }) {
  const [refundAmount, setRefundAmount] = useState('');
  const [refundReason, setRefundReason] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState('');

  useEffect(() => {
    setRefundAmount('');
    setRefundReason('');
    setLocalError('');
    setSubmitting(false);
  }, [record?.id]);

  const refundedTotal = useMemo(() => {
    if (!record) return 0;
    return (record.refunds || []).reduce(
      (sum, refund) => sum + (Number.parseInt(refund.amountPaise, 10) || 0),
      0,
    );
  }, [record]);

  if (!record) {
    return null;
  }

  const remaining = Math.max(0, (record.amountPaise || 0) - refundedTotal);
  const canRefund =
    record.status === 'paid' || record.status === 'partially_refunded';

  async function submitRefund(event) {
    event.preventDefault();
    setLocalError('');

    const requested = refundAmount.trim() === ''
      ? remaining
      : Number.parseInt(refundAmount, 10);

    if (!Number.isFinite(requested) || requested <= 0) {
      setLocalError('Refund amount must be a positive integer in paise.');
      return;
    }
    if (requested > remaining) {
      setLocalError(
        `Refund amount exceeds remaining ${formatAmount(remaining, record.currency)}.`,
      );
      return;
    }

    setSubmitting(true);
    try {
      await onRefund({ amountPaise: requested, reason: refundReason });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="drawer-backdrop" role="presentation" onClick={onClose}>
      <aside
        className="drawer-card"
        role="dialog"
        aria-modal="true"
        aria-label="Payment detail"
        onClick={(event) => event.stopPropagation()}
      >
        <header className="drawer-head">
          <div>
            <small>Payment</small>
            <h3>{record.id}</h3>
            <p className="status-line">
              <span className={`status-badge status-${record.status}`}>
                {record.status}
              </span>
              &nbsp;·&nbsp;{record.kind}
            </p>
          </div>
          <button
            type="button"
            className="secondary-button"
            onClick={onClose}
            disabled={submitting}
          >
            Close
          </button>
        </header>

        <section className="drawer-section">
          <h4>Transaction</h4>
          <KeyValue label="Amount">
            {formatAmount(record.amountPaise, record.currency)}
          </KeyValue>
          <KeyValue label="Razorpay order id">{record.razorpayOrderId}</KeyValue>
          <KeyValue label="Razorpay payment id">{record.razorpayPaymentId}</KeyValue>
          <KeyValue label="Method">{record.paymentMethod}</KeyValue>
          <KeyValue label="Created">{formatDateTime(record.createdAt)}</KeyValue>
          <KeyValue label="Paid at">{formatDateTime(record.paidAt)}</KeyValue>
          <KeyValue label="Failed at">{formatDateTime(record.failedAt)}</KeyValue>
          <KeyValue label="Refunded at">{formatDateTime(record.refundedAt)}</KeyValue>
          {record.errorCode ? (
            <KeyValue label="Error">
              {record.errorCode}: {record.errorDescription || ''}
            </KeyValue>
          ) : null}
        </section>

        <section className="drawer-section">
          <h4>User</h4>
          <KeyValue label="User id">{record.userId}</KeyValue>
          <KeyValue label="Email">{record.userEmail}</KeyValue>
        </section>

        <section className="drawer-section">
          <h4>Target</h4>
          <KeyValue label="Type">{record.target?.type}</KeyValue>
          <KeyValue label="Id">{record.target?.id}</KeyValue>
          <KeyValue label="Fee slug">{record.metadata?.feeSlug}</KeyValue>
          {record.metadata?.durationDays ? (
            <KeyValue label="Duration (days)">
              {record.metadata.durationDays}
            </KeyValue>
          ) : null}
        </section>

        <section className="drawer-section">
          <h4>Refunds ({record.refunds?.length || 0})</h4>
          {(!record.refunds || record.refunds.length === 0) ? (
            <p className="muted">No refunds yet.</p>
          ) : (
            <ul className="refund-list">
              {record.refunds.map((refund) => (
                <li key={refund.refundId}>
                  <strong>{refund.refundId}</strong>
                  <span>{formatAmount(refund.amountPaise, record.currency)}</span>
                  <small>{refund.reason || '—'}</small>
                  <small>{refund.byEmail || refund.by || ''}</small>
                </li>
              ))}
            </ul>
          )}

          {canRefund ? (
            <form className="refund-form" onSubmit={submitRefund}>
              <label className="field">
                <span>
                  Amount (paise) — leave blank for full remaining{' '}
                  {formatAmount(remaining, record.currency)}
                </span>
                <input
                  type="number"
                  min={1}
                  step={1}
                  value={refundAmount}
                  onChange={(event) => setRefundAmount(event.target.value)}
                  placeholder={String(remaining)}
                  disabled={submitting}
                />
              </label>
              <label className="field">
                <span>Reason</span>
                <input
                  type="text"
                  value={refundReason}
                  onChange={(event) => setRefundReason(event.target.value)}
                  placeholder="Why are we refunding this?"
                  disabled={submitting}
                />
              </label>
              {localError ? (
                <span className="field-error">{localError}</span>
              ) : null}
              <p className="muted">
                Acting as <strong>{adminEmail || 'unknown admin'}</strong>. This
                action is logged to <code>audit_logs</code>.
              </p>
              <button
                type="submit"
                className="primary-button"
                disabled={submitting}
              >
                {submitting ? 'Refunding…' : 'Issue refund'}
              </button>
            </form>
          ) : null}
        </section>

        <section className="drawer-section">
          <h4>Webhook events</h4>
          {record.webhookEventIds?.length ? (
            <ul className="plain-list">
              {record.webhookEventIds.map((eventId) => (
                <li key={eventId}>{eventId}</li>
              ))}
            </ul>
          ) : (
            <p className="muted">None received yet.</p>
          )}
        </section>
      </aside>
    </div>
  );
}
