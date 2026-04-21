import { useEffect, useMemo, useState } from 'react';
import { FeedbackBanner } from '../components/FeedbackBanner';
import { PanelCard } from '../components/PanelCard';
import { paymentsService } from '../services/paymentsService';
import { formatDateTime } from '../utils/format';
import { PaymentDetailDrawer } from '../components/PaymentDetailDrawer';

const STATUS_OPTIONS = [
  { value: 'all', label: 'All statuses' },
  { value: 'created', label: 'Created (awaiting payment)' },
  { value: 'paid', label: 'Paid' },
  { value: 'failed', label: 'Failed' },
  { value: 'refunded', label: 'Refunded' },
  { value: 'partially_refunded', label: 'Partially refunded' },
];

const KIND_OPTIONS = [
  { value: 'all', label: 'All kinds' },
  { value: 'boost', label: 'Boost' },
  { value: 'listing_fee', label: 'Listing fee' },
];

function formatAmount(paise, currency = 'INR') {
  const normalized = Number.parseInt(paise, 10);
  if (!Number.isFinite(normalized)) return '-';
  const rupees = normalized / 100;
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency,
    maximumFractionDigits: 2,
  }).format(rupees);
}

function statusBadgeClass(status) {
  switch (status) {
    case 'paid':
      return 'status-badge status-ok';
    case 'failed':
      return 'status-badge status-bad';
    case 'refunded':
    case 'partially_refunded':
      return 'status-badge status-warn';
    case 'created':
    default:
      return 'status-badge status-pending';
  }
}

export function PaymentsPage({ adminEmail }) {
  const [statusFilter, setStatusFilter] = useState('all');
  const [kindFilter, setKindFilter] = useState('all');
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState(null);
  const [actionFeedback, setActionFeedback] = useState({ error: '', success: '' });

  useEffect(() => {
    setLoading(true);
    setError('');
    const unsubscribe = paymentsService.subscribeFirstPage({
      statusFilter,
      kindFilter,
      pageSize: 100,
      onData: (next) => {
        setRecords(next);
        setLoading(false);
      },
      onError: (message) => {
        setError(message);
        setLoading(false);
      },
    });
    return () => {
      try {
        unsubscribe?.();
      } catch {
        // ignore
      }
    };
  }, [statusFilter, kindFilter]);

  const filteredRecords = useMemo(() => {
    const normalized = search.trim().toLowerCase();
    if (!normalized) return records;
    return records.filter((record) => {
      const haystack = [
        record.id,
        record.userId,
        record.userEmail,
        record.razorpayPaymentId,
        record.razorpayOrderId,
        record.target?.id,
        record.metadata?.feeSlug,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(normalized);
    });
  }, [records, search]);

  const selectedRecord = records.find((record) => record.id === selectedId) || null;

  const totals = useMemo(() => {
    const summary = { count: records.length, paidPaise: 0, refundedPaise: 0 };
    for (const record of records) {
      if (record.status === 'paid') {
        summary.paidPaise += record.amountPaise;
      }
      if (record.status === 'refunded' || record.status === 'partially_refunded') {
        for (const refund of record.refunds || []) {
          summary.refundedPaise += Number.parseInt(refund.amountPaise, 10) || 0;
        }
      }
    }
    return summary;
  }, [records]);

  async function handleRefund({ amountPaise, reason }) {
    if (!selectedRecord) return;
    setActionFeedback({ error: '', success: '' });
    try {
      const result = await paymentsService.refund({
        paymentId: selectedRecord.id,
        amountPaise,
        reason,
      });
      setActionFeedback({
        error: '',
        success: `Refund issued (${result?.status || 'ok'}).`,
      });
    } catch (error) {
      setActionFeedback({
        error: error?.message || 'Refund failed.',
        success: '',
      });
    }
  }

  return (
    <div className="page-stack">
      <PanelCard
        title="Payments"
        subtitle="Server-verified transactions. Refunds here call the Razorpay refund API via a Cloud Function and update the linked product."
      >
        <FeedbackBanner tone="error">{error}</FeedbackBanner>
        <FeedbackBanner tone="error">{actionFeedback.error}</FeedbackBanner>
        <FeedbackBanner tone="success">{actionFeedback.success}</FeedbackBanner>

        <div className="summary-grid">
          <div className="summary-card">
            <span className="summary-label">Records shown</span>
            <span className="summary-value">{totals.count}</span>
          </div>
          <div className="summary-card">
            <span className="summary-label">Paid (in view)</span>
            <span className="summary-value">{formatAmount(totals.paidPaise)}</span>
          </div>
          <div className="summary-card">
            <span className="summary-label">Refunded (in view)</span>
            <span className="summary-value">{formatAmount(totals.refundedPaise)}</span>
          </div>
        </div>

        <div className="toolbar">
          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
          >
            {STATUS_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <select
            value={kindFilter}
            onChange={(event) => setKindFilter(event.target.value)}
          >
            {KIND_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <input
            className="search-input"
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by user id, email, razorpay id, product id"
          />
          <div className="toolbar-note">{filteredRecords.length} visible</div>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Created</th>
                <th>User</th>
                <th>Kind</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Razorpay</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7}>
                    <div className="empty-state">Loading payments…</div>
                  </td>
                </tr>
              ) : filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan={7}>
                    <div className="empty-state">
                      No payments match the current filters.
                    </div>
                  </td>
                </tr>
              ) : (
                filteredRecords.map((record) => (
                  <tr key={record.id}>
                    <td>{formatDateTime(record.createdAt)}</td>
                    <td>
                      <div className="primary-cell">
                        <strong>{record.userEmail || record.userId || '—'}</strong>
                        <span>{record.userId || ''}</span>
                      </div>
                    </td>
                    <td>{record.kind || '—'}</td>
                    <td>{formatAmount(record.amountPaise, record.currency)}</td>
                    <td>
                      <span className={statusBadgeClass(record.status)}>
                        {record.status}
                      </span>
                    </td>
                    <td>
                      <div className="primary-cell">
                        <span>{record.razorpayPaymentId || '—'}</span>
                        <small>{record.razorpayOrderId || ''}</small>
                      </div>
                    </td>
                    <td>
                      <button
                        type="button"
                        className="secondary-button"
                        onClick={() => setSelectedId(record.id)}
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </PanelCard>

      <PaymentDetailDrawer
        record={selectedRecord}
        adminEmail={adminEmail}
        onClose={() => setSelectedId(null)}
        onRefund={handleRefund}
      />
    </div>
  );
}
