import { useEffect, useMemo, useState } from 'react';
import { ActionMenu } from '../components/ActionMenu';
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

function optionLabel(options, value) {
  return options.find((option) => option.value === value)?.label || value || '-';
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

        <div className="toolbar payments-toolbar">
          <div className="payments-filter-group">
            <label className="payments-filter">
              <span>Status</span>
              <select
                value={statusFilter}
                onChange={(event) => setStatusFilter(event.target.value)}
                aria-label="Filter by status"
              >
                {STATUS_OPTIONS.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="payments-filter">
              <span>Kind</span>
              <select
                value={kindFilter}
                onChange={(event) => setKindFilter(event.target.value)}
                aria-label="Filter by kind"
              >
                {KIND_OPTIONS.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
          <label className="payments-search-field">
            <span>Search payments</span>
            <input
              className="search-input"
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="User, email, Razorpay, or product ID"
            />
          </label>
          <div className="payments-toolbar-note">
            <strong>{filteredRecords.length}</strong>
            <span>{filteredRecords.length === 1 ? 'payment visible' : 'payments visible'}</span>
          </div>
        </div>

        <div className="table-wrap payments-table-wrap">
          <table className="data-table payments-table">
            <thead>
              <tr>
                <th>Payment</th>
                <th>Customer</th>
                <th>Type</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">Loading payments…</div>
                  </td>
                </tr>
              ) : filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">
                      No payments match the current filters.
                    </div>
                  </td>
                </tr>
              ) : (
                filteredRecords.map((record) => (
                  <tr key={record.id}>
                    <td>
                      <div className="payments-identity">
                        <strong>{formatAmount(record.amountPaise, record.currency)}</strong>
                        <span>{formatDateTime(record.createdAt)}</span>
                        <div className="payments-meta-row">
                          <span>{record.razorpayPaymentId || 'No payment id'}</span>
                          <span>{record.razorpayOrderId || 'No order id'}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="payments-user-cell">
                        <strong>{record.userEmail || record.userId || '-'}</strong>
                        <span>{record.userId || 'User id not recorded'}</span>
                      </div>
                    </td>
                    <td>
                      <div className="payments-kind-cell">
                        <strong>{optionLabel(KIND_OPTIONS, record.kind)}</strong>
                        <span>{record.metadata?.feeSlug || record.target?.type || 'No fee metadata'}</span>
                        <div className="payments-meta-row">
                          <span>{record.target?.id || 'No target id'}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="payments-status-cell">
                        <span className={statusBadgeClass(record.status)}>
                          {record.status || 'unknown'}
                        </span>
                        <span>{record.paymentMethod || optionLabel(STATUS_OPTIONS, record.status)}</span>
                      </div>
                    </td>
                    <td className="table-actions-cell">
                      <ActionMenu
                        label={`Manage payment ${record.id}`}
                        iconOnly
                        items={[
                          {
                            key: 'details',
                            label: 'View details',
                            icon: 'details',
                            onSelect() {
                              setSelectedId(record.id);
                            },
                          },
                        ]}
                      />
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
